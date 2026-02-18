//
//  AudioCaptureManager.swift
//  VoiceStreamSDK
//
//  Manages microphone audio capture
//

import Foundation
import AVFoundation

/// Internal audio capture manager for recording microphone input
internal class AudioCaptureManager {

    // MARK: - Properties

    private let config: VoiceStreamConfig
    private weak var callback: VoiceStreamCallback?

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isCapturing: Bool = false

    // Callback for captured audio data
    var onAudioCaptured: ((Data) -> Void)?

    // MARK: - Initialization

    init(config: VoiceStreamConfig) {
        self.config = config
    }

    // MARK: - Public Methods

    /// Set the callback for audio events
    func setCallback(_ callback: VoiceStreamCallback?) {
        self.callback = callback
    }

    /// Start capturing audio from microphone
    func startCapture() {
        guard !isCapturing else {
            log("Already capturing audio")
            return
        }

        // Check microphone permission
        checkMicrophonePermission { [weak self] granted in
            guard let self = self else { return }

            if granted {
                self.performStartCapture()
            } else {
                let error = VoiceStreamError.audioPermissionDenied("Microphone permission not granted")
                DispatchQueue.main.async {
                    self.callback?.onError(error: error)
                }
            }
        }
    }

    /// Stop capturing audio
    func stopCapture() {
        guard isCapturing else {
            log("Not currently capturing")
            return
        }

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        isCapturing = false

        log("Audio capture stopped")
    }

    /// Check if currently capturing
    func isCurrentlyCapturing() -> Bool {
        return isCapturing
    }

    /// Cleanup resources
    func cleanup() {
        stopCapture()
        callback = nil
        onAudioCaptured = nil
    }

    // MARK: - Private Methods

    private func performStartCapture() {
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)

            // Create audio engine
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else {
                throw NSError(domain: "AudioCaptureManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio engine"])
            }

            inputNode = audioEngine.inputNode

            // Get the input format
            let inputFormat = inputNode?.outputFormat(forBus: 0)
            guard let inputFormat = inputFormat else {
                throw NSError(domain: "AudioCaptureManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get input format"])
            }

            // Check if input format is valid (simulator may not have microphone)
            if inputFormat.sampleRate == 0 {
                throw NSError(
                    domain: "AudioCaptureManager",
                    code: -4,
                    userInfo: [
                        NSLocalizedDescriptionKey: "No audio input device available. This may occur on simulator. Please test on a real device or enable simulator microphone in I/O settings."
                    ]
                )
            }

            // Create desired format (16kHz, mono, 16-bit PCM)
            guard let desiredFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: config.audioInputSampleRate,
                channels: AVAudioChannelCount(config.audioChannels),
                interleaved: true
            ) else {
                throw NSError(domain: "AudioCaptureManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create desired audio format"])
            }

            // Create format converter if needed
            let needsConversion = inputFormat.sampleRate != desiredFormat.sampleRate ||
                                  inputFormat.channelCount != desiredFormat.channelCount

            // Calculate buffer size in frames
            let bufferSizeInBytes = config.audioBufferSize
            let bytesPerFrame = Int(desiredFormat.streamDescription.pointee.mBytesPerFrame)
            let bufferSizeInFrames = AVAudioFrameCount(bufferSizeInBytes / bytesPerFrame)

            log("Starting audio capture - Input: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch | Desired: \(desiredFormat.sampleRate)Hz, \(desiredFormat.channelCount)ch")

            // Install tap on input node
            inputNode?.installTap(onBus: 0, bufferSize: bufferSizeInFrames, format: inputFormat) { [weak self] buffer, time in
                guard let self = self else { return }

                // Convert to desired format if needed
                let processedBuffer: AVAudioPCMBuffer
                if needsConversion {
                    processedBuffer = self.convertBuffer(buffer, from: inputFormat, to: desiredFormat) ?? buffer
                } else {
                    processedBuffer = buffer
                }

                // Convert to Data
                if let audioData = self.bufferToData(processedBuffer) {
                    // Notify callback
                    self.onAudioCaptured?(audioData)

                    // Notify SDK callback
                    DispatchQueue.main.async {
                        self.callback?.onAudioSent(audioData: audioData)
                    }
                }
            }

            // Start the audio engine
            try audioEngine.start()
            isCapturing = true

            log("Audio capture started successfully")

        } catch {
            log("Failed to start audio capture: \(error.localizedDescription)")
            let voiceStreamError = VoiceStreamError.audioCaptureFailed(error.localizedDescription)
            DispatchQueue.main.async { [weak self] in
                self?.callback?.onError(error: voiceStreamError)
            }
        }
    }

    private func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            log("Microphone permission already granted")
            completion(true)

        case .denied:
            log("Microphone permission denied")
            completion(false)

        case .undetermined:
            log("Requesting microphone permission")
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                self.log("Microphone permission \(granted ? "granted" : "denied")")
                completion(granted)
            }

        @unknown default:
            log("Unknown microphone permission status")
            completion(false)
        }
    }

    private func convertBuffer(_ buffer: AVAudioPCMBuffer, from sourceFormat: AVAudioFormat, to destinationFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: sourceFormat, to: destinationFormat) else {
            log("Failed to create audio converter")
            return nil
        }

        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * destinationFormat.sampleRate / sourceFormat.sampleRate)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: destinationFormat, frameCapacity: capacity) else {
            log("Failed to create converted buffer")
            return nil
        }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            log("Audio conversion error: \(error.localizedDescription)")
            return nil
        }

        return convertedBuffer
    }

    private func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let channelData = buffer.int16ChannelData else {
            return nil
        }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        let dataSize = frameLength * channelCount * MemoryLayout<Int16>.size

        var data = Data(capacity: dataSize)

        // For mono or interleaved data
        if channelCount == 1 {
            let ptr = UnsafeBufferPointer(start: channelData[0], count: frameLength)
            data.append(UnsafeBufferPointer(start: ptr.baseAddress, count: frameLength))
        } else {
            // For stereo, interleave the channels
            for frame in 0..<frameLength {
                for channel in 0..<channelCount {
                    var sample = channelData[channel][frame]
                    data.append(UnsafeBufferPointer(start: &sample, count: 1))
                }
            }
        }

        return data
    }

    private func log(_ message: String) {
        if config.enableDebugLogging {
            print("[AudioCaptureManager] \(message)")
        }
    }
}
