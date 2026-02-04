//
//  VoiceStreamConfig.swift
//  VoiceStreamSDK
//
//  Configuration object for VoiceStreamSDK initialization
//

import Foundation

/// Configuration for VoiceStreamSDK
public struct VoiceStreamConfig {

    // MARK: - Server Configuration

    /// WebSocket server URL (e.g., "wss://streaming-poc.smartserve.ai/ws")
    public let serverUrl: String

    /// Unique tenant identifier
    public let tenantId: String

    /// Tenant display name
    public let tenantName: String

    /// Optional authentication token (Bearer token)
    public let authToken: String?

    // MARK: - Connection Configuration

    /// Enable automatic reconnection on connection loss
    public let autoReconnect: Bool

    /// Maximum number of reconnection attempts (0 = unlimited)
    public let maxReconnectAttempts: Int

    /// Initial reconnection delay in milliseconds
    public let reconnectDelayMs: Int

    /// Maximum reconnection delay in milliseconds (for exponential backoff)
    public let maxReconnectDelayMs: Int

    /// Ping interval in milliseconds for keep-alive
    public let pingIntervalMs: Int

    // MARK: - Audio Configuration

    /// Audio input sample rate (microphone capture) in Hz
    public let audioInputSampleRate: Double

    /// Audio output sample rate (speaker playback) in Hz
    public let audioOutputSampleRate: Double

    /// Number of audio channels (1 = mono, 2 = stereo)
    public let audioChannels: Int

    /// Audio bit depth (8, 16, 24, 32)
    public let audioBitDepth: Int

    /// Audio buffer size in bytes
    public let audioBufferSize: Int

    // MARK: - Debug Configuration

    /// Enable debug logging
    public let enableDebugLogging: Bool

    // MARK: - AI Clinic Voice Pipe Mode

    /// Enable AI Clinic mode (Voice Pipe - STT/TTS only)
    /// When enabled, the SDK receives transcripts and sends LLM responses instead of the backend calling an LLM
    public let aiClinicMode: Bool

    /// Custom English filler phrase (optional, backend has defaults)
    public let fillerPhraseEn: String?

    /// Custom Arabic filler phrase (optional, backend has defaults)
    public let fillerPhraseAr: String?

    // MARK: - Initialization

    /// Initialize VoiceStreamConfig with custom values
    /// - Parameters:
    ///   - serverUrl: WebSocket server URL
    ///   - tenantId: Unique tenant identifier
    ///   - tenantName: Tenant display name
    ///   - authToken: Optional authentication token
    ///   - autoReconnect: Enable automatic reconnection (default: true)
    ///   - maxReconnectAttempts: Maximum reconnection attempts (default: 5)
    ///   - reconnectDelayMs: Initial reconnection delay (default: 1000ms)
    ///   - maxReconnectDelayMs: Maximum reconnection delay (default: 30000ms)
    ///   - pingIntervalMs: Ping interval for keep-alive (default: 30000ms)
    ///   - enableDebugLogging: Enable debug logging (default: false)
    ///   - audioInputSampleRate: Input sample rate (default: 16000.0 Hz)
    ///   - audioOutputSampleRate: Output sample rate (default: 24000.0 Hz)
    ///   - audioChannels: Number of channels (default: 1 - mono)
    ///   - audioBitDepth: Bit depth (default: 16)
    ///   - audioBufferSize: Buffer size in bytes (default: 1600)
    ///   - aiClinicMode: Enable AI Clinic Voice Pipe mode (default: false)
    ///   - fillerPhraseEn: Custom English filler phrase (optional)
    ///   - fillerPhraseAr: Custom Arabic filler phrase (optional)
    public init(
        serverUrl: String = "wss://streaming-poc.smartserve.ai/ws",
        tenantId: String,
        tenantName: String,
        authToken: String? = nil,
        autoReconnect: Bool = true,
        maxReconnectAttempts: Int = 5,
        reconnectDelayMs: Int = 1000,
        maxReconnectDelayMs: Int = 30000,
        pingIntervalMs: Int = 30000,
        enableDebugLogging: Bool = false,
        audioInputSampleRate: Double = 16000.0,
        audioOutputSampleRate: Double = 24000.0,
        audioChannels: Int = 1,
        audioBitDepth: Int = 16,
        audioBufferSize: Int = 1600,
        aiClinicMode: Bool = false,
        fillerPhraseEn: String? = nil,
        fillerPhraseAr: String? = nil
    ) {
        self.serverUrl = serverUrl
        self.tenantId = tenantId
        self.tenantName = tenantName
        self.authToken = authToken
        self.autoReconnect = autoReconnect
        self.maxReconnectAttempts = maxReconnectAttempts
        self.reconnectDelayMs = reconnectDelayMs
        self.maxReconnectDelayMs = maxReconnectDelayMs
        self.pingIntervalMs = pingIntervalMs
        self.enableDebugLogging = enableDebugLogging
        self.audioInputSampleRate = audioInputSampleRate
        self.audioOutputSampleRate = audioOutputSampleRate
        self.audioChannels = audioChannels
        self.audioBitDepth = audioBitDepth
        self.audioBufferSize = audioBufferSize
        self.aiClinicMode = aiClinicMode
        self.fillerPhraseEn = fillerPhraseEn
        self.fillerPhraseAr = fillerPhraseAr
    }
}

// MARK: - CustomStringConvertible

extension VoiceStreamConfig: CustomStringConvertible {
    public var description: String {
        """
        VoiceStreamConfig(
            serverUrl: \(serverUrl),
            tenantId: \(tenantId),
            tenantName: \(tenantName),
            authToken: \(authToken != nil ? "[PRESENT]" : "[NONE]"),
            autoReconnect: \(autoReconnect),
            maxReconnectAttempts: \(maxReconnectAttempts),
            reconnectDelayMs: \(reconnectDelayMs),
            maxReconnectDelayMs: \(maxReconnectDelayMs),
            pingIntervalMs: \(pingIntervalMs),
            enableDebugLogging: \(enableDebugLogging),
            audioInputSampleRate: \(audioInputSampleRate) Hz,
            audioOutputSampleRate: \(audioOutputSampleRate) Hz,
            audioChannels: \(audioChannels),
            audioBitDepth: \(audioBitDepth),
            audioBufferSize: \(audioBufferSize) bytes,
            aiClinicMode: \(aiClinicMode),
            fillerPhraseEn: \(fillerPhraseEn ?? "[NONE]"),
            fillerPhraseAr: \(fillerPhraseAr ?? "[NONE]")
        )
        """
    }
}
