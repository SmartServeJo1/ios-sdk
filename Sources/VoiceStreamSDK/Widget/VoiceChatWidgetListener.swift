//
//  VoiceChatWidgetListener.swift
//  VoiceStreamSDK
//
//  Listener protocol for voice chat widget events
//

import Foundation

/// Protocol for receiving voice chat widget events
public protocol VoiceChatWidgetListener: AnyObject {

    /// Called when the widget's connection state changes
    /// - Parameter state: The new connection state
    func onConnectionStateChanged(state: ConnectionState)

    /// Called when an error occurs in the widget
    /// - Parameter error: The error that occurred
    func onError(error: VoiceStreamError)

    /// Called when the AI Clinic flow requires an LLM response
    /// The app must call the respond closure with the LLM's answer
    /// - Parameters:
    ///   - question: The user's transcribed question
    ///   - respond: Closure to call with the LLM response text
    func onLlmResponseRequired(question: String, respond: @escaping (String) -> Void)
}

// MARK: - Default Implementations

public extension VoiceChatWidgetListener {
    func onConnectionStateChanged(state: ConnectionState) {}
    func onError(error: VoiceStreamError) {}
    func onLlmResponseRequired(question: String, respond: @escaping (String) -> Void) {}
}
