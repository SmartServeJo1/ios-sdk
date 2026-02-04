//
//  VoiceStreamSDK.swift
//  VoiceStreamSDK
//
//  Main SDK class for real-time voice streaming
//

import Foundation
import AVFoundation

/// Main SDK class for VoiceStreamSDK (Singleton pattern)
public class VoiceStreamSDK {

    // MARK: - Singleton

    private static var instance: VoiceStreamSDK?
    private static let lock = NSLock()

    // MARK: - Properties

    private let config: VoiceStreamConfig
    private let webSocketManager: WebSocketManager
    private let audioCaptureManager: AudioCaptureManager
    private let audioPlaybackManager: AudioPlaybackManager

    private weak var callback: VoiceStreamCallback?

    // Closure-based callbacks (alternative to protocol)
    public var onConnectedHandler: (() -> Void)?
    public var onMessageHandler: ((String) -> Void)?
    public var onAudioReceivedHandler: ((Data) -> Void)?
    public var onAudioSentHandler: ((Data) -> Void)?
    public var onErrorHandler: ((VoiceStreamError) -> Void)?
    public var onDisconnectedHandler: ((String) -> Void)?

    // AI Clinic Voice Pipe Mode callbacks
    /// Called when transcript is received (AI Clinic mode)
    /// Parameters: (text, isFinal, language)
    public var onTranscriptHandler: ((String, Bool, String) -> Void)?
    /// Called when filler phrase starts playing (AI Clinic mode)
    public var onFillerStartedHandler: (() -> Void)?

    // MARK: - Initialization

    /// Private initializer (use initialize() instead)
    private init(config: VoiceStreamConfig) {
        self.config = config
        self.webSocketManager = WebSocketManager(config: config)
        self.audioCaptureManager = AudioCaptureManager(config: config)
        self.audioPlaybackManager = AudioPlaybackManager(config: config)

        setupInternalCallbacks()
        log("VoiceStreamSDK initialized with config: \(config)")
    }

    // MARK: - Public Static Methods

    /// Initialize the VoiceStreamSDK singleton
    /// - Parameter config: Configuration for the SDK
    /// - Returns: The SDK singleton instance
    public static func initialize(config: VoiceStreamConfig) -> VoiceStreamSDK {
        lock.lock()
        defer { lock.unlock() }

        if let existing = instance {
            print("[VoiceStreamSDK] Warning: SDK already initialized, returning existing instance")
            return existing
        }

        let newInstance = VoiceStreamSDK(config: config)
        instance = newInstance
        return newInstance
    }

    /// Get the VoiceStreamSDK singleton instance
    /// - Returns: The SDK singleton instance
    /// - Throws: Error if SDK not initialized
    public static func getInstance() throws -> VoiceStreamSDK {
        lock.lock()
        defer { lock.unlock() }

        guard let instance = instance else {
            throw VoiceStreamError.unknown("SDK not initialized. Call initialize() first.")
        }

        return instance
    }

    /// Reset the SDK instance (for testing only)
    public static func reset() {
        lock.lock()
        defer { lock.unlock() }

        instance?.cleanup()
        instance = nil
    }

    // MARK: - Public Instance Methods - Callback

    /// Set the callback object for SDK events
    /// - Parameter object: Object conforming to VoiceStreamCallback protocol
    public func setCallback(object: VoiceStreamCallback?) {
        self.callback = object
    }

    // MARK: - Public Instance Methods - Connection

    /// Connect to the WebSocket server
    public func connect() {
        log("Connecting to server...")
        webSocketManager.connect()
    }

    /// Disconnect from the WebSocket server
    public func disconnect() {
        log("Disconnecting from server...")
        stopAudioStreaming()
        webSocketManager.disconnect()
    }

    /// Check if connected to server
    /// - Returns: True if connected, false otherwise
    public func isConnected() -> Bool {
        return webSocketManager.isConnected()
    }

    /// Get current connection state
    /// - Returns: The current connection state
    public func getConnectionState() -> ConnectionState {
        return webSocketManager.getConnectionState()
    }

    // MARK: - Public Instance Methods - Audio Streaming

    /// Start audio streaming (capture and playback)
    public func startAudioStreaming() {
        guard isConnected() else {
            log("Cannot start audio streaming: not connected")
            let error = VoiceStreamError.audioCaptureFailed("Not connected to server")
            handleError(error)
            return
        }

        log("Starting audio streaming...")

        // Start audio capture
        audioCaptureManager.startCapture()

        // Start audio playback
        audioPlaybackManager.startPlayback()
    }

    /// Stop audio streaming (capture and playback)
    public func stopAudioStreaming() {
        log("Stopping audio streaming...")

        // Stop audio capture
        audioCaptureManager.stopCapture()

        // Stop audio playback
        audioPlaybackManager.stopPlayback()
    }

    /// Check if audio streaming is active
    /// - Returns: True if streaming, false otherwise
    public func isStreaming() -> Bool {
        return audioCaptureManager.isCurrentlyCapturing() || audioPlaybackManager.isCurrentlyPlaying()
    }

    // MARK: - Public Instance Methods - Messaging

    /// Send a text message to the server
    /// - Parameter text: The text message to send
    public func sendMessage(_ text: String) {
        log("Sending message: \(text)")
        webSocketManager.sendText(text)
    }

    // MARK: - AI Clinic Voice Pipe Mode

    /// Send LLM response to be spoken via TTS (AI Clinic mode only)
    /// Call this after receiving a transcript and getting a response from your LLM
    /// - Parameter text: The response text to be spoken
    public func sendLlmResponse(text: String) {
        guard config.aiClinicMode else {
            log("Warning: sendLlmResponse called but AI Clinic mode is not enabled")
            return
        }

        let message: [String: Any] = [
            "type": "llm_response",
            "text": text
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            log("Sending LLM response: \(text.prefix(100))...")
            webSocketManager.sendText(jsonString)
        } else {
            log("Error: Failed to serialize LLM response")
            handleError(.messageSendFailed("Failed to serialize LLM response"))
        }
    }

    // MARK: - Public Instance Methods - Lifecycle

    /// Cleanup all resources
    public func cleanup() {
        log("Cleaning up SDK resources...")

        stopAudioStreaming()
        webSocketManager.cleanup()
        audioCaptureManager.cleanup()
        audioPlaybackManager.cleanup()

        callback = nil
        onConnectedHandler = nil
        onMessageHandler = nil
        onAudioReceivedHandler = nil
        onAudioSentHandler = nil
        onErrorHandler = nil
        onDisconnectedHandler = nil
        onTranscriptHandler = nil
        onFillerStartedHandler = nil
    }

    // MARK: - Private Methods

    private func setupInternalCallbacks() {
        // Setup WebSocket callbacks
        webSocketManager.setCallback(self)

        // Setup audio capture callbacks
        audioCaptureManager.setCallback(self)
        audioCaptureManager.onAudioCaptured = { [weak self] audioData in
            guard let self = self else { return }
            // Send captured audio to server
            self.webSocketManager.sendBinary(audioData)
        }

        // Setup audio playback callbacks
        audioPlaybackManager.setCallback(self)
    }

    private func handleError(_ error: VoiceStreamError) {
        DispatchQueue.main.async { [weak self] in
            self?.callback?.onError(error: error)
            self?.onErrorHandler?(error)
        }
    }

    private func log(_ message: String) {
        if config.enableDebugLogging {
            print("[VoiceStreamSDK] \(message)")
        }
    }
}

// MARK: - VoiceStreamCallback

extension VoiceStreamSDK: VoiceStreamCallback {

    public func onConnected() {
        log("Connected to server")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onConnected()
            self.onConnectedHandler?()
        }
    }

    public func onMessage(message: String) {
        log("Received message: \(message)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onMessage(message: message)
            self.onMessageHandler?(message)
        }
    }

    public func onAudioReceived(audioData: Data) {
        log("Received audio: \(audioData.count) bytes")

        // Queue audio for playback
        audioPlaybackManager.queueAudio(audioData)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onAudioReceived(audioData: audioData)
            self.onAudioReceivedHandler?(audioData)
        }
    }

    public func onAudioSent(audioData: Data) {
        // Optional callback - not logged to reduce noise
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onAudioSent(audioData: audioData)
            self.onAudioSentHandler?(audioData)
        }
    }

    public func onError(error: VoiceStreamError) {
        log("Error occurred: \(error)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onError(error: error)
            self.onErrorHandler?(error)
        }
    }

    public func onDisconnected(reason: String) {
        log("Disconnected: \(reason)")

        // Stop audio streaming on disconnect
        stopAudioStreaming()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onDisconnected(reason: reason)
            self.onDisconnectedHandler?(reason)
        }
    }

    public func onTranscript(text: String, isFinal: Bool, language: String) {
        log("Transcript received: \(text.prefix(100))... (final: \(isFinal), lang: \(language))")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onTranscript(text: text, isFinal: isFinal, language: language)
            self.onTranscriptHandler?(text, isFinal, language)
        }
    }

    public func onFillerStarted() {
        log("Filler phrase started")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onFillerStarted()
            self.onFillerStartedHandler?()
        }
    }
}
