# VoiceStreamSDK iOS - Integration Guide

Complete step-by-step guide for integrating VoiceStreamSDK into your iOS application.

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Project Configuration](#project-configuration)
4. [SDK Integration](#sdk-integration)
5. [Advanced Configuration](#advanced-configuration)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Requirements

### System Requirements

- **Xcode**: 14.0 or later
- **iOS Deployment Target**: 14.0 or later
- **Swift**: 5.9 or later
- **macOS**: 12.0 or later (for development)

### Dependencies

The SDK uses the following dependencies (automatically managed):

- **Starscream**: 4.0+ (WebSocket client)
- **AVFoundation**: Built-in (Audio handling)

## Installation

### Method 1: Swift Package Manager (Recommended)

1. **Add Package to Xcode**
   - Open your project in Xcode
   - File → Add Packages...
   - Enter repository URL or select local package
   - Choose version/branch
   - Select target to add the package

2. **Add to Package.swift** (for Swift packages)
   ```swift
   dependencies: [
       .package(url: "https://github.com/yourusername/VoiceStreamSDK-iOS.git", from: "1.0.0")
   ]
   ```

3. **Import in Code**
   ```swift
   import VoiceStreamSDK
   ```

### Method 2: Local Integration

1. **Copy SDK Files**
   - Copy `VoiceStreamSDK` folder to your project
   - Drag into Xcode project navigator
   - Ensure "Copy items if needed" is checked

2. **Link Framework**
   - Project settings → General → Frameworks, Libraries, and Embedded Content
   - Add VoiceStreamSDK framework

### Method 3: CocoaPods (Optional)

Create a `Podfile`:

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  pod 'VoiceStreamSDK', '~> 1.0'
end
```

Run:
```bash
pod install
```

## Project Configuration

### 1. Info.plist Configuration

Add required permissions:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Microphone Permission -->
    <key>NSMicrophoneUsageDescription</key>
    <string>We need access to your microphone for voice streaming</string>

    <!-- Optional: Background Audio -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
</dict>
</plist>
```

### 2. App Transport Security (if needed)

For custom servers without HTTPS:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note**: Only use this for development. Production should use WSS (secure WebSocket).

### 3. Build Settings

Ensure these settings in your target:

- **iOS Deployment Target**: 14.0 or later
- **Swift Language Version**: 5.0
- **Enable Bitcode**: No (if using pre-built framework)

## SDK Integration

### Basic Integration

#### Step 1: Import SDK

```swift
import VoiceStreamSDK
import AVFoundation  // For audio session management
```

#### Step 2: Create Configuration

```swift
let config = VoiceStreamConfig(
    serverUrl: "wss://streaming-poc.smartserve.ai/ws",
    tenantId: "your-tenant-id",
    tenantName: "Your Tenant Name",
    enableDebugLogging: true  // Enable for development
)
```

#### Step 3: Initialize SDK

```swift
// Initialize (call once during app startup)
let sdk = VoiceStreamSDK.initialize(config: config)

// Later, get instance
do {
    let sdk = try VoiceStreamSDK.getInstance()
} catch {
    print("SDK not initialized: \(error)")
}
```

#### Step 4: Set Up Callbacks

**Option A: Using Protocol**

```swift
class MyViewController: UIViewController, VoiceStreamCallback {
    private var sdk: VoiceStreamSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        sdk = try? VoiceStreamSDK.getInstance()
        sdk?.setCallback(object: self)
    }

    // MARK: - VoiceStreamCallback

    func onConnected() {
        print("Connected to server")
        // Update UI on main thread
        DispatchQueue.main.async {
            self.updateConnectionStatus(true)
        }
    }

    func onMessage(message: String) {
        print("Received message: \(message)")
    }

    func onAudioReceived(audioData: Data) {
        print("Received audio: \(audioData.count) bytes")
    }

    func onAudioSent(audioData: Data) {
        // Optional: track sent audio
    }

    func onError(error: VoiceStreamError) {
        print("Error: \(error)")
        DispatchQueue.main.async {
            self.showError(error)
        }
    }

    func onDisconnected(reason: String) {
        print("Disconnected: \(reason)")
        DispatchQueue.main.async {
            self.updateConnectionStatus(false)
        }
    }
}
```

**Option B: Using Closures**

```swift
class MyViewController: UIViewController {
    private var sdk: VoiceStreamSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        sdk = try? VoiceStreamSDK.getInstance()
        setupCallbacks()
    }

    private func setupCallbacks() {
        sdk?.onConnected = { [weak self] in
            DispatchQueue.main.async {
                self?.handleConnected()
            }
        }

        sdk?.onMessage = { [weak self] message in
            DispatchQueue.main.async {
                self?.handleMessage(message)
            }
        }

        sdk?.onAudioReceived = { [weak self] audioData in
            // Audio callback (high frequency)
            self?.handleAudio(audioData)
        }

        sdk?.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.handleError(error)
            }
        }

        sdk?.onDisconnected = { [weak self] reason in
            DispatchQueue.main.async {
                self?.handleDisconnected(reason)
            }
        }
    }
}
```

#### Step 5: Connection Management

```swift
// Connect to server
func connect() {
    sdk?.connect()
}

// Disconnect from server
func disconnect() {
    sdk?.disconnect()
}

// Check connection status
func checkStatus() {
    if sdk?.isConnected() == true {
        print("Connected")
    }

    let state = sdk?.getConnectionState()
    print("State: \(state?.description ?? "unknown")")
}
```

#### Step 6: Audio Streaming

```swift
// Start audio streaming (after connection)
func startStreaming() {
    guard sdk?.isConnected() == true else {
        print("Not connected")
        return
    }

    sdk?.startAudioStreaming()
}

// Stop audio streaming
func stopStreaming() {
    sdk?.stopAudioStreaming()
}

// Check streaming status
func isCurrentlyStreaming() -> Bool {
    return sdk?.isStreaming() ?? false
}
```

#### Step 7: Cleanup

```swift
deinit {
    sdk?.cleanup()
}

// Or when done
func shutdown() {
    sdk?.cleanup()
    VoiceStreamSDK.reset()  // For testing/reset
}
```

### SwiftUI Integration

```swift
import SwiftUI
import VoiceStreamSDK

class VoiceStreamViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isStreaming = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var eventLog: [String] = []

    private var sdk: VoiceStreamSDK?

    init() {
        initializeSDK()
    }

    private func initializeSDK() {
        let config = VoiceStreamConfig(
            serverUrl: "wss://streaming-poc.smartserve.ai/ws",
            tenantId: "your-tenant-id",
            tenantName: "Your Tenant Name",
            enableDebugLogging: true
        )

        sdk = VoiceStreamSDK.initialize(config: config)
        setupCallbacks()
    }

    private func setupCallbacks() {
        sdk?.onConnected = { [weak self] in
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.connectionState = .connected
                self?.addLog("Connected")
            }
        }

        sdk?.onDisconnected = { [weak self] reason in
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.isStreaming = false
                self?.connectionState = .disconnected
                self?.addLog("Disconnected: \(reason)")
            }
        }

        sdk?.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.addLog("Error: \(error.localizedDescription)")
            }
        }
    }

    func connect() {
        sdk?.connect()
        addLog("Connecting...")
    }

    func disconnect() {
        sdk?.disconnect()
    }

    func startStreaming() {
        sdk?.startAudioStreaming()
        isStreaming = true
        addLog("Streaming started")
    }

    func stopStreaming() {
        sdk?.stopAudioStreaming()
        isStreaming = false
        addLog("Streaming stopped")
    }

    private func addLog(_ message: String) {
        eventLog.append(message)
    }

    deinit {
        sdk?.cleanup()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = VoiceStreamViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Status: \(viewModel.connectionState.description)")

            Button("Connect") {
                viewModel.connect()
            }
            .disabled(viewModel.isConnected)

            Button("Start Streaming") {
                viewModel.startStreaming()
            }
            .disabled(!viewModel.isConnected || viewModel.isStreaming)

            Button("Stop") {
                viewModel.stopStreaming()
                viewModel.disconnect()
            }

            List(viewModel.eventLog, id: \.self) { log in
                Text(log)
            }
        }
        .padding()
    }
}
```

## Advanced Configuration

### Custom Audio Settings

```swift
let config = VoiceStreamConfig(
    serverUrl: "wss://your-server.com/ws",
    tenantId: "tenant123",
    tenantName: "My Tenant",

    // Audio Input (Microphone)
    audioInputSampleRate: 16000.0,      // 16 kHz
    audioChannels: 1,                    // Mono
    audioBitDepth: 16,                   // 16-bit
    audioBufferSize: 3200,               // 200ms buffer

    // Audio Output (Speaker)
    audioOutputSampleRate: 24000.0,      // 24 kHz

    // Connection
    autoReconnect: true,
    maxReconnectAttempts: 10,
    reconnectDelayMs: 2000,
    maxReconnectDelayMs: 60000,

    // Keep-alive
    pingIntervalMs: 30000,               // 30 seconds

    // Authentication
    authToken: "your-bearer-token",

    // Debug
    enableDebugLogging: false
)
```

### Background Audio Support

Configure audio session for background operation:

```swift
import AVFoundation

func configureAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()

    do {
        // Set category for background audio
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetooth]
        )

        // Activate session
        try audioSession.setActive(true)

        print("Audio session configured")
    } catch {
        print("Audio session error: \(error)")
    }
}

// Call before starting streaming
configureAudioSession()
sdk?.startAudioStreaming()
```

### Authentication

For servers requiring authentication:

```swift
let config = VoiceStreamConfig(
    serverUrl: "wss://secure-server.com/ws",
    tenantId: "tenant123",
    tenantName: "My Tenant",
    authToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  // JWT token
)
```

The SDK automatically adds the `Authorization: Bearer <token>` header to the WebSocket connection.

## Best Practices

### 1. Singleton Management

```swift
// Initialize once
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
        let config = VoiceStreamConfig(...)
        _ = VoiceStreamSDK.initialize(config: config)
        return true
    }
}

// Use throughout app
class SomeViewController: UIViewController {
    func setup() {
        if let sdk = try? VoiceStreamSDK.getInstance() {
            // Use SDK
        }
    }
}
```

### 2. Memory Management

Always use `[weak self]` in closures:

```swift
sdk?.onConnected = { [weak self] in
    self?.handleConnected()
}
```

### 3. Error Handling

Implement comprehensive error handling:

```swift
sdk?.onError = { [weak self] error in
    switch error {
    case .audioPermissionDenied(let message):
        self?.showPermissionAlert()

    case .connectionFailed(let message):
        self?.showConnectionError(message)

    case .audioCaptureFailed(let message):
        self?.handleAudioError(message)

    default:
        self?.showGenericError(error.localizedDescription)
    }
}
```

### 4. Permission Handling

Request microphone permission early:

```swift
import AVFoundation

func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async {
            completion(granted)
        }
    }
}

// Use it
requestMicrophonePermission { granted in
    if granted {
        self.sdk?.connect()
    } else {
        self.showPermissionDeniedAlert()
    }
}
```

### 5. Lifecycle Management

```swift
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup SDK callbacks
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Don't auto-connect here
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Don't auto-disconnect
    }

    deinit {
        // Cleanup
        sdk?.cleanup()
    }
}
```

## Troubleshooting

### Common Issues

**1. SDK Not Initialized Error**

```swift
// Problem
let sdk = try VoiceStreamSDK.getInstance()  // Throws error

// Solution
let config = VoiceStreamConfig(...)
let sdk = VoiceStreamSDK.initialize(config: config)
```

**2. Microphone Permission Denied**

```swift
// Check permission status
let status = AVAudioSession.sharedInstance().recordPermission

switch status {
case .granted:
    // Permission granted
case .denied:
    // Show settings alert
case .undetermined:
    // Request permission
}
```

**3. Connection Fails Immediately**

- Check server URL format (must start with `wss://` or `ws://`)
- Verify internet connectivity
- Check firewall/network restrictions
- Enable debug logging to see detailed errors

**4. No Audio Playback**

- Check device is not muted
- Verify audio session configuration
- Check that `startAudioStreaming()` was called
- Ensure audio data is being received in callbacks

**5. Build Errors**

```bash
# Clean build
Product → Clean Build Folder (⇧⌘K)

# Update packages
File → Packages → Update to Latest Package Versions

# Reset package cache
File → Packages → Reset Package Caches
```

## Next Steps

- Check out the [Demo App](DemoApp/) for a complete reference
- Read the [API Reference](README.md#api-reference)
- Review [Quick Start Guide](QUICK_START.md) for faster integration
- Test with different network conditions

## Support

For issues or questions, please open an issue on GitHub or contact support.
