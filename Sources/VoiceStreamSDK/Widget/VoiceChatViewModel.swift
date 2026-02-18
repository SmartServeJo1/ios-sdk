//
//  VoiceChatViewModel.swift
//  VoiceStreamSDK
//
//  ViewModel managing voice chat widget state and SDK interaction
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for the VoiceChatView widget
public class VoiceChatViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var messages: [ChatMessage] = []
    @Published public var isExpanded: Bool = false
    @Published public var isStreaming: Bool = false
    @Published public var isConnected: Bool = false
    @Published public var connectionState: ConnectionState = .disconnected
    @Published public var subtitle: String = "Tap to start"
    @Published public var textInput: String = ""

    // MARK: - Properties

    public let theme: VoiceChatTheme
    public weak var listener: VoiceChatWidgetListener?

    private var sdk: VoiceStreamSDK?
    private let config: VoiceStreamConfig
    private var hasConnectedOnce: Bool = false

    // MARK: - Initialization

    public init(config: VoiceStreamConfig, theme: VoiceChatTheme = .default) {
        self.config = config
        self.theme = theme
    }

    deinit {
        sdk?.disconnect()
        sdk?.cleanup()
        VoiceStreamSDK.reset()
    }

    // MARK: - Public Methods

    /// Toggle the widget expanded/collapsed state
    public func toggleExpanded() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }

        // Auto-connect on first expand
        if isExpanded && !hasConnectedOnce {
            connect()
        }
    }

    /// Connect to the voice server
    public func connect() {
        if sdk == nil {
            VoiceStreamSDK.reset()
            sdk = VoiceStreamSDK.initialize(config: config)
            setupCallbacks()
        }

        subtitle = "Connecting..."
        sdk?.connect()
    }

    /// Disconnect from the voice server
    public func disconnect() {
        sdk?.disconnect()
    }

    /// Toggle microphone streaming on/off
    public func toggleMic() {
        if isStreaming {
            sdk?.stopAudioStreaming()
            isStreaming = false
            subtitle = "Mic off"
        } else {
            guard isConnected else {
                connect()
                return
            }
            sdk?.startAudioStreaming()
            isStreaming = true
            subtitle = "Listening..."
        }
    }

    /// Send the current text input as a chat message
    public func sendTextMessage() {
        let text = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user bubble
        let userMessage = ChatMessage(type: .user, text: text)
        addMessage(userMessage)
        textInput = ""

        // Ensure connected and playback ready
        if !isConnected {
            connect()
        }
        sdk?.ensurePlayback()

        if config.aiClinicMode {
            // AI Clinic flow: send as chat message, the backend will route it
            sdk?.sendChatMessage(text: text)

            // Add thinking indicator
            let thinking = ChatMessage(type: .thinking, text: "")
            addMessage(thinking)
        } else {
            // Standard mode: send as regular message
            sdk?.sendChatMessage(text: text)
        }
    }

    // MARK: - Message Management

    private func addMessage(_ message: ChatMessage) {
        DispatchQueue.main.async { [weak self] in
            self?.messages.append(message)
        }
    }

    private func removeThinkingMessages() {
        DispatchQueue.main.async { [weak self] in
            self?.messages.removeAll { $0.type == .thinking }
        }
    }

    private func addSystemMessage(_ text: String) {
        let message = ChatMessage(type: .system, text: text)
        addMessage(message)
    }

    // MARK: - SDK Callback Setup

    private func setupCallbacks() {
        sdk?.onConnectedHandler = { [weak self] in
            guard let self = self else { return }
            self.isConnected = true
            self.connectionState = .connected
            self.hasConnectedOnce = true
            self.subtitle = "Connected"
            self.listener?.onConnectionStateChanged(state: .connected)
        }

        sdk?.onDisconnectedHandler = { [weak self] reason in
            guard let self = self else { return }
            self.isConnected = false
            self.isStreaming = false
            self.connectionState = .disconnected
            self.subtitle = "Disconnected"
            self.listener?.onConnectionStateChanged(state: .disconnected)
        }

        sdk?.onErrorHandler = { [weak self] error in
            guard let self = self else { return }
            self.listener?.onError(error: error)
            self.addSystemMessage("Connection error occurred")
        }

        sdk?.onTranscriptHandler = { [weak self] text, isFinal, language, requiresResponse in
            guard let self = self, isFinal else { return }

            // Add user message bubble
            let userMessage = ChatMessage(type: .user, text: text, language: language)
            self.addMessage(userMessage)

            if requiresResponse {
                // Add thinking indicator
                let thinking = ChatMessage(type: .thinking, text: "")
                self.addMessage(thinking)

                // Ask listener for LLM response
                self.listener?.onLlmResponseRequired(question: text) { [weak self] response in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        // Remove thinking, add assistant response
                        self.removeThinkingMessages()
                        let assistantMessage = ChatMessage(type: .assistant, text: response, language: language)
                        self.addMessage(assistantMessage)

                        // Send response to backend for TTS
                        self.sdk?.sendLlmResponse(text: response)
                    }
                }
            }
        }

        sdk?.onLlmRequiredHandler = { [weak self] question in
            guard let self = self else { return }

            // Add thinking indicator (user bubble already shown via transcript)
            if !self.messages.contains(where: { $0.type == .thinking }) {
                let thinking = ChatMessage(type: .thinking, text: "")
                self.addMessage(thinking)
            }

            // Ask listener for LLM response
            self.listener?.onLlmResponseRequired(question: question) { [weak self] response in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    // Remove thinking, add assistant response
                    self.removeThinkingMessages()
                    let assistantMessage = ChatMessage(type: .assistant, text: response)
                    self.addMessage(assistantMessage)

                    // Send response to backend for TTS
                    self.sdk?.sendLlmResponse(text: response)
                }
            }
        }

        sdk?.onAssistantMessageHandler = { [weak self] text in
            guard let self = self else { return }
            self.removeThinkingMessages()
            let message = ChatMessage(type: .assistant, text: text)
            self.addMessage(message)
        }

        sdk?.onFillerStartedHandler = { [weak self] in
            guard let self = self else { return }
            // Only add thinking if not already showing
            if !self.messages.contains(where: { $0.type == .thinking }) {
                let thinking = ChatMessage(type: .thinking, text: "")
                self.addMessage(thinking)
            }
        }

        sdk?.onInterruptHandler = { [weak self] in
            guard let self = self else { return }
            self.sdk?.clearAudioQueue()
            self.removeThinkingMessages()
        }

        sdk?.onMessageHandler = { [weak self] message in
            // Handle any other messages if needed
            _ = self
        }
    }
}
