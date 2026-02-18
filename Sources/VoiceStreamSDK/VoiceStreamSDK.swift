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

    // AI Clinic Mode callbacks
    /// Called when transcript is received (AI Clinic mode)
    /// Parameters: (text, isFinal, language, requiresResponse)
    /// When requiresResponse is true, call sendLlmResponse() with your LLM's answer
    /// When requiresResponse is false, the system handled it (greeting/pleasantry)
    public var onTranscriptHandler: ((String, Bool, String, Bool) -> Void)?
    /// Called when system responds to greeting/pleasantry on its own (AI Clinic mode)
    /// Parameter: response text (for display/logging only)
    public var onAssistantMessageHandler: ((String) -> Void)?
    /// Called when the server is waiting for LLM response (AI Clinic mode)
    public var onFillerStartedHandler: (() -> Void)?

    /// Called when server detects a question requiring LLM delegation (AI Clinic mode)
    /// The filler phrase has already been shown. App should call sendLlmResponse() with the answer.
    public var onLlmRequiredHandler: ((String) -> Void)?

    /// Called when server signals AI session is ready (greeting audio will follow)
    public var onReadyHandler: (() -> Void)?
    /// Called when server sends an interrupt signal
    public var onInterruptHandler: (() -> Void)?
    /// Called when server sends a diagnostic warning
    public var onDiagnosticHandler: ((String, String) -> Void)?

    // Echo prevention
    private var micMuted: Bool = false
    private var unmuteWorkItem: DispatchWorkItem?

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

    /// Send a chat text message to the server
    /// - Parameter text: The chat message text
    public func sendChatMessage(text: String) {
        let message: [String: Any] = [
            "type": "chat_message",
            "text": text
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            log("Sending chat message: \(text.prefix(100))...")
            webSocketManager.sendText(jsonString)
        } else {
            log("Error: Failed to serialize chat message")
            handleError(.messageSendFailed("Failed to serialize chat message"))
        }
    }

    /// Start audio playback only (no capture) - useful for text-only users who want to hear TTS
    public func ensurePlayback() {
        guard isConnected() else {
            log("Cannot ensure playback: not connected")
            return
        }

        if !audioPlaybackManager.isCurrentlyPlaying() {
            log("Starting playback-only mode...")
            audioPlaybackManager.startPlayback()
        }
    }

    /// Clear the audio playback queue and unmute microphone
    public func clearAudioQueue() {
        log("Clearing audio queue")
        audioPlaybackManager.clearQueue()
        micMuted = false
        unmuteWorkItem?.cancel()
        unmuteWorkItem = nil
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
        onAssistantMessageHandler = nil
        onFillerStartedHandler = nil
        onLlmRequiredHandler = nil
        onReadyHandler = nil
        onInterruptHandler = nil
        onDiagnosticHandler = nil
        unmuteWorkItem?.cancel()
        unmuteWorkItem = nil
    }

    // MARK: - Private Methods

    private func setupInternalCallbacks() {
        // Setup WebSocket callbacks
        webSocketManager.setCallback(self)

        // Setup audio capture callbacks
        audioCaptureManager.setCallback(self)
        audioCaptureManager.onAudioCaptured = { [weak self] audioData in
            guard let self = self else { return }
            // Echo prevention: skip sending audio when mic is muted
            guard !self.micMuted else { return }
            // Send captured audio to server
            self.webSocketManager.sendBinary(audioData)
        }

        // Setup audio playback callbacks
        audioPlaybackManager.setCallback(self)

        // Echo prevention: safety unmute when playback finishes
        audioPlaybackManager.onPlaybackIdle = { [weak self] in
            self?.scheduleUnmute()
        }
    }

    private func muteForEchoPrevention() {
        micMuted = true
        // Cancel any pending unmute — mic stays muted until playback finishes
        unmuteWorkItem?.cancel()
        unmuteWorkItem = nil
    }

    private func scheduleUnmute() {
        // Only called from onPlaybackIdle (all buffers done).
        // Wait an additional tail delay for speaker echo to decay before unmuting.
        unmuteWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.micMuted = false
            self?.log("Mic unmuted (echo prevention - playback idle + tail)")
        }
        unmuteWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
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

        // Echo prevention: mute mic while receiving/playing audio.
        // Do NOT schedule unmute here — unmute only happens after
        // onPlaybackIdle fires (all buffers finished playing + tail delay).
        muteForEchoPrevention()

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

    public func onTranscript(text: String, isFinal: Bool, language: String, requiresResponse: Bool) {
        log("Transcript received: \(text.prefix(100))... (final: \(isFinal), lang: \(language), needsLLM: \(requiresResponse))")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onTranscript(text: text, isFinal: isFinal, language: language, requiresResponse: requiresResponse)
            self.onTranscriptHandler?(text, isFinal, language, requiresResponse)
        }
    }

    public func onAssistantMessage(text: String) {
        log("Assistant message: \(text.prefix(100))...")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onAssistantMessage(text: text)
            self.onAssistantMessageHandler?(text)
        }
    }

    public func onFillerStarted() {
        log("Waiting for LLM response")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onFillerStarted()
            self.onFillerStartedHandler?()
        }
    }

    public func onLlmRequired(question: String) {
        log("LLM required for: \(question.prefix(100))...")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onLlmRequired(question: question)
            self.onLlmRequiredHandler?(question)
        }
    }

    public func onReady() {
        log("AI session ready — greeting audio will follow")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onReady()
            self.onReadyHandler?()
        }
    }

    public func onInterrupt() {
        log("Interrupt received")

        // Clear audio queue on interrupt
        clearAudioQueue()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onInterrupt()
            self.onInterruptHandler?()
        }
    }

    public func onDiagnostic(code: String, message: String) {
        log("Diagnostic [\(code)]: \(message)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callback?.onDiagnostic(code: code, message: message)
            self.onDiagnosticHandler?(code, message)
        }
    }
}
