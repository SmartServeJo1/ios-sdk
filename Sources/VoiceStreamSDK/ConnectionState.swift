//
//  ConnectionState.swift
//  VoiceStreamSDK
//
//  Connection state enumeration
//

import Foundation

/// Connection state for VoiceStreamSDK
public enum ConnectionState {
    /// Not connected to server
    case disconnected

    /// Attempting to connect to server
    case connecting

    /// Successfully connected to server
    case connected

    /// Attempting to reconnect after connection loss
    case reconnecting
}

// MARK: - CustomStringConvertible

extension ConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting"
        }
    }
}

// MARK: - Equatable

extension ConnectionState: Equatable {}
