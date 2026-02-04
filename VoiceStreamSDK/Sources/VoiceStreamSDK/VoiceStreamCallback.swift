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

    // MARK: - AI Clinic Voice Pipe Mode Callbacks

    /// Called when a transcript is received from server (AI Clinic mode only)
    /// The app should call their LLM with this transcript, then call sendLlmResponse()
    /// - Parameters:
    ///   - text: The transcribed user speech
    ///   - isFinal: Whether this is the final transcript (always true currently)
    ///   - language: Detected language ("en" or "ar")
    func onTranscript(text: String, isFinal: Bool, language: String)

    /// Called when the server starts playing a filler phrase (AI Clinic mode only)
    /// Indicates the server is waiting for the LLM response
    func onFillerStarted()
}

// MARK: - Default Implementations

public extension VoiceStreamCallback {
    /// Default implementation for onConnected
    func onConnected() {}

    /// Default implementation for onMessage
    func onMessage(message: String) {}

    /// Default implementation for onAudioReceived
    func onAudioReceived(audioData: Data) {}

    /// Default implementation for onAudioSent
    func onAudioSent(audioData: Data) {}

    /// Default implementation for onError
    func onError(error: VoiceStreamError) {}

    /// Default implementation for onDisconnected
    func onDisconnected(reason: String) {}

    /// Default implementation for onTranscript (AI Clinic mode)
    func onTranscript(text: String, isFinal: Bool, language: String) {}

    /// Default implementation for onFillerStarted (AI Clinic mode)
    func onFillerStarted() {}
}
