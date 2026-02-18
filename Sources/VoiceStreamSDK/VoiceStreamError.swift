//
//  VoiceStreamError.swift
//  VoiceStreamSDK
//
//  Error types for VoiceStreamSDK
//

import Foundation

/// Errors that can occur during VoiceStreamSDK operation
public enum VoiceStreamError: Error {

    /// Connection to server failed
    case connectionFailed(String)

    /// Authentication with server failed
    case authenticationFailed(String)

    /// Connection was disconnected
    case disconnected(String)

    /// Reconnection attempts failed
    case reconnectionFailed(String)

    /// Audio capture (microphone) failed
    case audioCaptureFailed(String)

    /// Audio playback (speaker) failed
    case audioPlaybackFailed(String)

    /// Microphone permission denied
    case audioPermissionDenied(String)

    /// Received invalid message from server
    case invalidMessage(String)

    /// Failed to send message to server
    case messageSendFailed(String)

    /// Unknown error occurred
    case unknown(String)
}

// MARK: - LocalizedError

extension VoiceStreamError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .disconnected(let message):
            return "Disconnected: \(message)"
        case .reconnectionFailed(let message):
            return "Reconnection failed: \(message)"
        case .audioCaptureFailed(let message):
            return "Audio capture failed: \(message)"
        case .audioPlaybackFailed(let message):
            return "Audio playback failed: \(message)"
        case .audioPermissionDenied(let message):
            return "Audio permission denied: \(message)"
        case .invalidMessage(let message):
            return "Invalid message: \(message)"
        case .messageSendFailed(let message):
            return "Message send failed: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - CustomStringConvertible

extension VoiceStreamError: CustomStringConvertible {
    public var description: String {
        errorDescription ?? "VoiceStreamError"
    }
}
