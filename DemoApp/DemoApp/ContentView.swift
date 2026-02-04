//
//  ContentView.swift
//  DemoApp
//
//  Main view for VoiceStreamSDK Demo
//

import SwiftUI
import VoiceStreamSDK

struct ContentView: View {
    @StateObject private var viewModel = DemoViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status
                    statusSection

                    // Control Buttons
                    controlButtonsSection

                    // Metrics
                    metricsSection

                    // Event Log
                    eventLogSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("VoiceStream Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.initializeSDK()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 12) {
            Text("Connection Status")
                .font(.headline)

            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                Text(viewModel.connectionState.description)
                    .font(.subheadline)
            }

            if viewModel.isConnected {
                Text("Connected for \(viewModel.connectionDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }

    private var statusColor: Color {
        switch viewModel.connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .red
        }
    }

    // MARK: - Control Buttons

    private var controlButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.connect()
                }) {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isConnected ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isConnected)

                Button(action: {
                    viewModel.disconnect()
                }) {
                    Text("Disconnect")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isConnected ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isConnected)
            }

            HStack(spacing: 12) {
                Button(action: {
                    viewModel.startStreaming()
                }) {
                    Text("Start Streaming")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isStreaming || !viewModel.isConnected ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isStreaming || !viewModel.isConnected)

                Button(action: {
                    viewModel.stopStreaming()
                }) {
                    Text("Stop Streaming")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isStreaming ? Color.orange : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isStreaming)
            }
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(spacing: 12) {
            Text("Metrics")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                MetricRow(label: "Data Sent", value: viewModel.formatBytes(viewModel.bytesSent))
                MetricRow(label: "Data Received", value: viewModel.formatBytes(viewModel.bytesReceived))
                MetricRow(label: "Messages Received", value: "\(viewModel.messagesReceived)")

                if viewModel.latencySamples.count > 0 {
                    Divider()
                    MetricRow(label: "Avg Latency", value: String(format: "%.0f ms", viewModel.averageLatency))
                    MetricRow(label: "Min Latency", value: String(format: "%.0f ms", viewModel.minLatency))
                    MetricRow(label: "Max Latency", value: String(format: "%.0f ms", viewModel.maxLatency))
                    MetricRow(label: "P95 Latency", value: String(format: "%.0f ms", viewModel.p95Latency))
                    MetricRow(label: "Jitter", value: String(format: "%.0f ms", viewModel.jitter))

                    HStack {
                        Text("Quality")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.latencyQuality)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.latencyQualityColor)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Event Log Section

    private var eventLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Event Log")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    viewModel.clearEventLog()
                }
                .font(.caption)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.eventLog.reversed(), id: \.timestamp) { event in
                        HStack(alignment: .top, spacing: 8) {
                            Text(event.timeString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)

                            Text(event.message)
                                .font(.caption)
                                .foregroundColor(event.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Metric Row

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Event Log Entry

struct EventLogEntry {
    let timestamp: Date
    let message: String
    let type: EventType

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var color: Color {
        switch type {
        case .info:
            return .primary
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    enum EventType {
        case info, success, warning, error
    }
}

// MARK: - Demo View Model

class DemoViewModel: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isConnected: Bool = false
    @Published var isStreaming: Bool = false
    @Published var eventLog: [EventLogEntry] = []
    @Published var connectionDuration: String = "00:00:00"

    @Published var bytesSent: Int = 0
    @Published var bytesReceived: Int = 0
    @Published var messagesReceived: Int = 0
    @Published var latencySamples: [Double] = []

    private var sdk: VoiceStreamSDK?
    private var connectionStartTime: Date?
    private var durationTimer: Timer?
    private var lastAudioSentTime: Date?

    // MARK: - SDK Initialization

    func initializeSDK() {
        let config = VoiceStreamConfig(
            serverUrl: "wss://streaming-poc.smartserve.ai/ws",
            tenantId: "smartserve",
            tenantName: "SmartServe",
            enableDebugLogging: true
        )

        sdk = VoiceStreamSDK.initialize(config: config)
        setupCallbacks()

        addEvent("SDK initialized", type: .info)
    }

    // MARK: - Callbacks Setup

    private func setupCallbacks() {
        sdk?.onConnectedHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.handleConnected()
            }
        }

        sdk?.onMessageHandler = { [weak self] message in
            DispatchQueue.main.async {
                self?.handleMessage(message)
            }
        }

        sdk?.onAudioReceivedHandler = { [weak self] audioData in
            DispatchQueue.main.async {
                self?.handleAudioReceived(audioData)
            }
        }

        sdk?.onAudioSentHandler = { [weak self] audioData in
            DispatchQueue.main.async {
                self?.handleAudioSent(audioData)
            }
        }

        sdk?.onErrorHandler = { [weak self] error in
            DispatchQueue.main.async {
                self?.handleError(error)
            }
        }

        sdk?.onDisconnectedHandler = { [weak self] reason in
            DispatchQueue.main.async {
                self?.handleDisconnected(reason)
            }
        }
    }

    // MARK: - Connection Control

    func connect() {
        sdk?.connect()
        addEvent("Connecting to server...", type: .info)
    }

    func disconnect() {
        sdk?.disconnect()
        addEvent("Disconnecting...", type: .info)
    }

    func startStreaming() {
        sdk?.startAudioStreaming()
        addEvent("Starting audio streaming...", type: .info)
        isStreaming = true
    }

    func stopStreaming() {
        sdk?.stopAudioStreaming()
        addEvent("Stopping audio streaming...", type: .info)
        isStreaming = false
    }

    func cleanup() {
        stopDurationTimer()
        sdk?.cleanup()
    }

    // MARK: - Event Handlers

    private func handleConnected() {
        connectionState = .connected
        isConnected = true
        connectionStartTime = Date()
        startDurationTimer()
        addEvent("Connected to server", type: .success)
    }

    private func handleMessage(_ message: String) {
        messagesReceived += 1
        addEvent("Message: \(message)", type: .info)
    }

    private func handleAudioReceived(_ audioData: Data) {
        bytesReceived += audioData.count

        // Calculate latency
        if let sentTime = lastAudioSentTime {
            let latency = Date().timeIntervalSince(sentTime) * 1000 // in milliseconds
            latencySamples.append(latency)

            // Keep only last 100 samples
            if latencySamples.count > 100 {
                latencySamples.removeFirst()
            }
        }
    }

    private func handleAudioSent(_ audioData: Data) {
        bytesSent += audioData.count
        lastAudioSentTime = Date()
    }

    private func handleError(_ error: VoiceStreamError) {
        addEvent("Error: \(error.localizedDescription)", type: .error)
    }

    private func handleDisconnected(_ reason: String) {
        connectionState = .disconnected
        isConnected = false
        isStreaming = false
        stopDurationTimer()
        connectionDuration = "00:00:00"
        addEvent("Disconnected: \(reason)", type: .warning)
    }

    // MARK: - Event Log

    func addEvent(_ message: String, type: EventLogEntry.EventType) {
        let event = EventLogEntry(timestamp: Date(), message: message, type: type)
        eventLog.append(event)

        // Keep only last 50 events
        if eventLog.count > 50 {
            eventLog.removeFirst()
        }
    }

    func clearEventLog() {
        eventLog.removeAll()
    }

    // MARK: - Duration Timer

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    private func updateDuration() {
        guard let startTime = connectionStartTime else { return }

        let duration = Int(Date().timeIntervalSince(startTime))
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60

        connectionDuration = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Metrics Calculation

    var averageLatency: Double {
        guard !latencySamples.isEmpty else { return 0 }
        return latencySamples.reduce(0, +) / Double(latencySamples.count)
    }

    var minLatency: Double {
        latencySamples.min() ?? 0
    }

    var maxLatency: Double {
        latencySamples.max() ?? 0
    }

    var p95Latency: Double {
        guard !latencySamples.isEmpty else { return 0 }
        let sorted = latencySamples.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }

    var jitter: Double {
        guard latencySamples.count > 1 else { return 0 }

        var differences: [Double] = []
        for i in 1..<latencySamples.count {
            differences.append(abs(latencySamples[i] - latencySamples[i - 1]))
        }

        return differences.reduce(0, +) / Double(differences.count)
    }

    var latencyQuality: String {
        let avg = averageLatency
        if avg < 100 {
            return "Excellent"
        } else if avg < 200 {
            return "Good"
        } else if avg < 500 {
            return "Fair"
        } else {
            return "Poor"
        }
    }

    var latencyQualityColor: Color {
        let avg = averageLatency
        if avg < 100 {
            return .green
        } else if avg < 200 {
            return .blue
        } else if avg < 500 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Formatting

    func formatBytes(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
