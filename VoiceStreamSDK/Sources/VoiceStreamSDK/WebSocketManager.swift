//
//  WebSocketManager.swift
//  VoiceStreamSDK
//
//  Manages WebSocket connection with automatic reconnection
//

import Foundation
import Starscream

/// Internal WebSocket manager for handling server connection
internal class WebSocketManager: NSObject {

    // MARK: - Properties

    private var socket: WebSocket?
    private let config: VoiceStreamConfig
    private weak var callback: VoiceStreamCallback?

    private var connectionState: ConnectionState = .disconnected
    private var reconnectAttempts: Int = 0
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var isManualDisconnect: Bool = false

    // MARK: - Initialization

    init(config: VoiceStreamConfig) {
        self.config = config
        super.init()
    }

    // MARK: - Public Methods

    /// Set the callback for WebSocket events
    func setCallback(_ callback: VoiceStreamCallback?) {
        self.callback = callback
    }

    /// Connect to WebSocket server
    func connect() {
        guard connectionState == .disconnected else {
            log("Already connected or connecting")
            return
        }

        isManualDisconnect = false
        performConnect()
    }

    /// Disconnect from WebSocket server
    func disconnect() {
        isManualDisconnect = true
        stopPingTimer()
        stopReconnectTimer()

        let wasConnected = connectionState == .connected
        connectionState = .disconnected
        socket?.disconnect()
        socket = nil

        log("Disconnected from WebSocket")
        
        // Manually trigger callback if we were connected, to ensure UI updates
        if wasConnected {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.callback?.onDisconnected(reason: "Manual disconnect")
            }
        }
    }

    /// Send text message to server
    func sendText(_ text: String) {
        guard connectionState == .connected else {
            log("Cannot send text: not connected")
            callback?.onError(error: .messageSendFailed("Not connected"))
            return
        }

        socket?.write(string: text) { [weak self] in
            self?.log("Text message sent: \(text)")
        }
    }

    /// Send binary data to server
    func sendBinary(_ data: Data) {
        guard connectionState == .connected else {
            log("Cannot send binary: not connected")
            return
        }

        socket?.write(data: data) { [weak self] in
            self?.log("Binary data sent: \(data.count) bytes")
        }
    }

    /// Get current connection state
    func getConnectionState() -> ConnectionState {
        return connectionState
    }

    /// Check if connected
    func isConnected() -> Bool {
        return connectionState == .connected
    }

    /// Cleanup resources
    func cleanup() {
        disconnect()
        callback = nil
    }

    // MARK: - Private Methods

    private func performConnect() {
        guard let url = URL(string: config.serverUrl) else {
            log("Invalid server URL: \(config.serverUrl)")
            callback?.onError(error: .connectionFailed("Invalid server URL"))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        // Add authentication header if token is provided
        if let authToken = config.authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        socket = WebSocket(request: request)
        socket?.delegate = self

        connectionState = .connecting
        log("Connecting to \(config.serverUrl)...")

        socket?.connect()
    }

    private func scheduleReconnect() {
        guard config.autoReconnect else {
            log("Auto-reconnect is disabled")
            return
        }

        guard config.maxReconnectAttempts == 0 || reconnectAttempts < config.maxReconnectAttempts else {
            log("Maximum reconnect attempts reached")
            callback?.onError(error: .reconnectionFailed("Maximum attempts reached"))
            connectionState = .disconnected
            return
        }

        reconnectAttempts += 1
        connectionState = .reconnecting

        // Calculate exponential backoff delay
        let baseDelay = Double(config.reconnectDelayMs) / 1000.0
        let maxDelay = Double(config.maxReconnectDelayMs) / 1000.0
        let delay = min(baseDelay * pow(2.0, Double(reconnectAttempts - 1)), maxDelay)

        log("Scheduling reconnect attempt \(reconnectAttempts) in \(delay)s")

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.performConnect()
        }
    }

    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    private func startPingTimer() {
        stopPingTimer()

        let interval = Double(config.pingIntervalMs) / 1000.0
        pingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }

        log("Ping timer started with interval \(interval)s")
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        socket?.write(ping: Data()) { [weak self] in
            self?.log("Ping sent")
        }
    }

    private func sendTenantInfo() {
        let tenantInfo: [String: Any] = [
            "type": "tenant_info",
            "tenant_id": config.tenantId,
            "tenant_name": config.tenantName
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: tenantInfo, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            sendText(jsonString)
            log("Tenant info sent")
        }
    }

    private func log(_ message: String) {
        if config.enableDebugLogging {
            print("[WebSocketManager] \(message)")
        }
    }
}

// MARK: - WebSocketDelegate

extension WebSocketManager: WebSocketDelegate {

    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        switch event {
        case .connected(let headers):
            log("WebSocket connected with headers: \(headers)")
            connectionState = .connected
            reconnectAttempts = 0

            startPingTimer()
            sendTenantInfo()

            DispatchQueue.main.async { [weak self] in
                self?.callback?.onConnected()
            }

        case .disconnected(let reason, let code):
            log("WebSocket disconnected: \(reason) (code: \(code))")
            stopPingTimer()

            let previousState = connectionState
            connectionState = .disconnected

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.callback?.onDisconnected(reason: reason)
            }

            // Attempt reconnection if not manual disconnect
            if !isManualDisconnect && previousState != .reconnecting {
                scheduleReconnect()
            }

        case .text(let text):
            log("Received text: \(text)")

            // Try to parse as JSON for special message types (AI Clinic mode)
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let messageType = json["type"] as? String {

                switch messageType {
                case "transcript":
                    // AI Clinic mode: transcript received
                    if let transcriptText = json["text"] as? String {
                        let isFinal = json["is_final"] as? Bool ?? true
                        let language = json["language"] as? String ?? "en"
                        let requiresResponse = json["requires_response"] as? Bool ?? true
                        DispatchQueue.main.async { [weak self] in
                            self?.callback?.onTranscript(text: transcriptText, isFinal: isFinal, language: language, requiresResponse: requiresResponse)
                        }
                        return
                    }
                case "assistant_message":
                    // AI Clinic mode: system handled response (for greetings/pleasantries)
                    if let responseText = json["text"] as? String {
                        DispatchQueue.main.async { [weak self] in
                            self?.callback?.onAssistantMessage(text: responseText)
                        }
                        return
                    }
                case "filler_started":
                    // AI Clinic mode: waiting for LLM response
                    DispatchQueue.main.async { [weak self] in
                        self?.callback?.onFillerStarted()
                    }
                    return
                case "interrupt":
                    // Interrupt signal - already handled as general message
                    break
                default:
                    break
                }
            }

            // Forward as general message
            DispatchQueue.main.async { [weak self] in
                self?.callback?.onMessage(message: text)
            }

        case .binary(let data):
            log("Received binary: \(data.count) bytes")
            DispatchQueue.main.async { [weak self] in
                self?.callback?.onAudioReceived(audioData: data)
            }

        case .pong(_):
            log("Pong received")

        case .ping(_):
            log("Ping received")

        case .error(let error):
            let errorMessage = error?.localizedDescription ?? "Unknown error"
            log("WebSocket error: \(errorMessage)")

            DispatchQueue.main.async { [weak self] in
                self?.callback?.onError(error: .connectionFailed(errorMessage))
            }

        case .viabilityChanged(let isViable):
            log("Viability changed: \(isViable)")

        case .reconnectSuggested(let shouldReconnect):
            log("Reconnect suggested: \(shouldReconnect)")
            if shouldReconnect && !isManualDisconnect {
                scheduleReconnect()
            }

        case .cancelled:
            log("WebSocket cancelled")
            connectionState = .disconnected

        case .peerClosed:
            log("Peer closed connection")
            stopPingTimer()
            connectionState = .disconnected

            if !isManualDisconnect {
                scheduleReconnect()
            }
        }
    }
}
