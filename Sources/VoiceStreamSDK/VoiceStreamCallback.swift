//
//  VoiceStreamCallback.swift
//  VoiceStreamSDK
//
//  Callback protocol for VoiceStreamSDK events
//

import Foundation

/// Protocol for receiving VoiceStreamSDK events
public protocol VoiceStreamCallback: AnyObject {

    /// Called when connection to server is established
    func onConnected()

    /// Called when a text message is received from server
    /// - Parameter message: The received message text
    func onMessage(message: String)

    /// Called when audio data is received from server
    /// - Parameter audioData: The received audio data (24kHz PCM)
    func onAudioReceived(audioData: Data)

    /// Called when audio data is sent to server (optional callback)
    /// - Parameter audioData: The sent audio data (16kHz PCM)
    func onAudioSent(audioData: Data)

    /// Called when an error occurs
    /// - Parameter error: The error that occurred
    func onError(error: VoiceStreamError)

    /// Called when disconnected from server
    /// - Parameter reason: The reason for disconnection
    func onDisconnected(reason: String)

    // MARK: - AI Clinic Mode Callbacks

    /// Called when a transcript is received from server (AI Clinic mode)
    /// - Parameters:
    ///   - text: The transcribed user speech
    ///   - isFinal: Whether this is the final transcript (always true currently)
    ///   - language: Detected language ("en" or "ar")
    ///   - requiresResponse: If true, app must call sendLlmResponse(). If false, system handled it.
    func onTranscript(text: String, isFinal: Bool, language: String, requiresResponse: Bool)

    /// Called when the system responds to a greeting/pleasantry on its own (AI Clinic mode)
    /// No action needed - this is for display/logging only
    /// - Parameter text: The system's conversational response
    func onAssistantMessage(text: String)

    /// Called when the server is waiting for LLM response (AI Clinic mode)
    /// Indicates a real question was forwarded - app should call sendLlmResponse()
    func onFillerStarted()

    /// Called when the server detects a question requiring LLM delegation (AI Clinic mode)
    /// The server has already shown a filler phrase ("One moment please...").
    /// App should call sendLlmResponse() with the LLM's answer.
    /// - Parameter question: The user's question that needs an LLM response
    func onLlmRequired(question: String)

    /// Called when server signals that the AI session is ready (Gemini setup complete)
    /// Greeting audio will follow shortly after this signal
    func onReady()

    /// Called when server sends an interrupt signal (clear audio, stop playback)
    func onInterrupt()

    /// Called when server sends a diagnostic warning
    /// - Parameters:
    ///   - code: Diagnostic code identifier
    ///   - message: Human-readable diagnostic message
    func onDiagnostic(code: String, message: String)
}

// MARK: - Default Implementations

public extension VoiceStreamCallback {
    func onConnected() {}
    func onMessage(message: String) {}
    func onAudioReceived(audioData: Data) {}
    func onAudioSent(audioData: Data) {}
    func onError(error: VoiceStreamError) {}
    func onDisconnected(reason: String) {}
    func onTranscript(text: String, isFinal: Bool, language: String, requiresResponse: Bool) {}
    func onAssistantMessage(text: String) {}
    func onFillerStarted() {}
    func onLlmRequired(question: String) {}
    func onReady() {}
    func onInterrupt() {}
    func onDiagnostic(code: String, message: String) {}
}
