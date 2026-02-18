//
//  AudioPlaybackManager.swift
//  VoiceStreamSDK
//
//  Manages speaker audio playback
//

import Foundation
import AVFoundation

/// Internal audio playback manager for playing audio to speaker
internal class AudioPlaybackManager {

    // MARK: - Properties

    private let config: VoiceStreamConfig
    private weak var callback: VoiceStreamCallback?

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var isPlaying: Bool = false

    private var audioFormat: AVAudioFormat?
    private let audioQueue = DispatchQueue(label: "com.smartserve.voicestream.audioplayback", qos: .userInteractive)

    // Volume amplification factor (default 3.0x like Android version)
    private let volumeAmplification: Float = 3.0

    // Echo prevention: track pending buffer count
    private var pendingBufferCount: Int = 0
    private let bufferLock = NSLock()

    /// Called when all scheduled audio buffers have finished playing
    var onPlaybackIdle: (() -> Void)?

    // MARK: - Initialization

    init(config: VoiceStreamConfig) {
        self.config = config
    }

    // MARK: - Public Methods

    /// Set the callback for audio events
    func setCallback(_ callback: VoiceStreamCallback?) {
        self.callback = callback
    }

    /// Start audio playback
    func startPlayback() {
        guard !isPlaying else {
            log("Already playing audio")
            return
        }

        performStartPlayback()
    }

    /// Stop audio playback
    func stopPlayback() {
        guard isPlaying else {
            log("Not currently playing")
            return
        }

        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        audioFormat = nil
        isPlaying = false

        log("Audio playback stopped")
    }

    /// Queue audio data for playback (auto-starts playback if needed)
    func queueAudio(_ data: Data) {
        // Auto-start playback if not already playing (supports greeting-first flow)
        if !isPlaying {
            log("Auto-starting playback for incoming audio")
            performStartPlayback()
        }

        guard isPlaying else {
            log("Cannot queue audio: playback failed to start")
            return
        }

        audioQueue.async { [weak self] in
            self?.processAndPlayAudio(data)
        }
    }

    /// Clear all queued audio and restart playback node
    func clearQueue() {
        audioQueue.async { [weak self] in
            guard let self = self, self.isPlaying, let playerNode = self.playerNode else { return }
            playerNode.stop()
            self.bufferLock.lock()
            self.pendingBufferCount = 0
            self.bufferLock.unlock()
            playerNode.play()
            self.log("Audio queue cleared")
        }
    }

    /// Check if currently playing
    func isCurrentlyPlaying() -> Bool {
        return isPlaying
    }

    /// Cleanup resources
    func cleanup() {
        stopPlayback()
        callback = nil
        onPlaybackIdle = nil
    }

    // MARK: - Private Methods

    private func performStartPlayback() {
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)

            // Create audio engine and player node
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()

            guard let audioEngine = audioEngine, let playerNode = playerNode else {
                throw NSError(domain: "AudioPlaybackManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio engine or player node"])
            }

            // Create audio format (24kHz, mono, 16-bit PCM)
            guard let format = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: config.audioOutputSampleRate,
                channels: AVAudioChannelCount(config.audioChannels),
                interleaved: true
            ) else {
                throw NSError(domain: "AudioPlaybackManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio format"])
            }

            audioFormat = format

            // Attach and connect player node
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

            // Start the audio engine
            try audioEngine.start()

            // Start the player node
            playerNode.play()

            isPlaying = true
            log("Audio playback started successfully at \(format.sampleRate)Hz, \(format.channelCount) channel(s)")

        } catch {
            log("Failed to start audio playback: \(error.localizedDescription)")
            let voiceStreamError = VoiceStreamError.audioPlaybackFailed(error.localizedDescription)
            DispatchQueue.main.async { [weak self] in
                self?.callback?.onError(error: voiceStreamError)
            }
        }
    }

    private func processAndPlayAudio(_ data: Data) {
        guard let audioFormat = audioFormat else {
            log("Audio format not available")
            return
        }

        // Convert Data to PCM buffer
        guard let buffer = createAudioBuffer(from: data, format: audioFormat) else {
            log("Failed to create audio buffer from data")
            return
        }

        // Apply volume amplification
        amplifyBuffer(buffer, factor: volumeAmplification)

        // Track pending buffers for idle detection
        bufferLock.lock()
        pendingBufferCount += 1
        bufferLock.unlock()

        // Schedule buffer for playback
        playerNode?.scheduleBuffer(buffer) { [weak self] in
            guard let self = self else { return }
            self.log("Audio buffer played: \(data.count) bytes")

            self.bufferLock.lock()
            self.pendingBufferCount -= 1
            let idle = self.pendingBufferCount <= 0
            self.pendingBufferCount = max(0, self.pendingBufferCount)
            self.bufferLock.unlock()

            if idle {
                DispatchQueue.main.async {
                    self.onPlaybackIdle?()
                }
            }
        }
    }

    private func createAudioBuffer(from data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        let frameCount = data.count / bytesPerFrame

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        // Copy data to buffer
        guard let channelData = buffer.int16ChannelData else {
            return nil
        }

        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            guard let baseAddress = ptr.baseAddress else { return }
            let samples = baseAddress.assumingMemoryBound(to: Int16.self)

            let channelCount = Int(format.channelCount)

            if channelCount == 1 {
                // Mono: direct copy
                for i in 0..<frameCount {
                    channelData[0][i] = samples[i]
                }
            } else {
                // Stereo or multi-channel: deinterleave
                for frame in 0..<frameCount {
                    for channel in 0..<channelCount {
                        let sampleIndex = frame * channelCount + channel
                        channelData[channel][frame] = samples[sampleIndex]
                    }
                }
            }
        }

        return buffer
    }

    private func amplifyBuffer(_ buffer: AVAudioPCMBuffer, factor: Float) {
        guard let channelData = buffer.int16ChannelData else {
            return
        }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        for channel in 0..<channelCount {
            for frame in 0..<frameLength {
                let sample = channelData[channel][frame]
                let amplified = Float(sample) * factor

                // Clamp to Int16 range to prevent clipping
                let clamped = max(Float(Int16.min), min(Float(Int16.max), amplified))
                channelData[channel][frame] = Int16(clamped)
            }
        }
    }

    private func log(_ message: String) {
        if config.enableDebugLogging {
            print("[AudioPlaybackManager] \(message)")
        }
    }
}
