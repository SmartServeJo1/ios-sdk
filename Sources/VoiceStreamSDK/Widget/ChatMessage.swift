//
//  ChatMessage.swift
//  VoiceStreamSDK
//
//  Chat message model for the voice chat widget
//

import Foundation

/// Type of chat message
public enum ChatMessageType: Equatable {
    case user
    case assistant
    case system
    case thinking
}

/// A single chat message in the voice chat widget
public struct ChatMessage: Identifiable, Equatable {
    public let id: String
    public let type: ChatMessageType
    public var text: String
    public var language: String
    public let timestamp: Date
    public var isInterim: Bool

    public init(
        id: String = UUID().uuidString,
        type: ChatMessageType,
        text: String,
        language: String = "en",
        timestamp: Date = Date(),
        isInterim: Bool = false
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.language = language
        self.timestamp = timestamp
        self.isInterim = isInterim
    }

    public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.isInterim == rhs.isInterim
    }
}
