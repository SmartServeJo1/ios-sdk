# VoiceStreamSDK - Quick Setup Guide

This guide will help you integrate the VoiceStreamSDK into your iOS application in just a few minutes.

## Prerequisites

- iOS 14.0+
- Xcode 14.0+
- Swift 5.9+

## Installation Methods

### Method 1: Swift Package Manager (Recommended)

#### Option A: Using Xcode UI

1. Open your Xcode project
2. Go to **File → Add Packages...**
3. Enter the repository URL: `https://github.com/yourusername/VoiceStreamSDK-iOS.git`
4. Select the version you want to use
5. Click **Add Package**
6. Select your target and click **Add Package** again

#### Option B: Using Package.swift

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/VoiceStreamSDK-iOS.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["VoiceStreamSDK"]
    )
]
```

### Method 2: Manual Installation

1. Clone or download this repository
2. Drag the `VoiceStreamSDK` folder into your Xcode project
3. Make sure **"Copy items if needed"** is checked
4. Select your target and click **Finish**
5. The SDK will be added to your project

## Configuration

### 1. Add Required Permissions

Add the following to your app's `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for voice streaming</string>
```

For background audio (optional):

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### 2. Basic Integration

#### Import the SDK

```swift
import VoiceStreamSDK
```

#### Initialize the SDK

```swift
let config = VoiceStreamConfig(
    serverUrl: "wss://your-server-url.com/ws",
    tenantId: "your-tenant-id",
    tenantName: "Your Tenant Name",
    enableDebugLogging: true  // Optional: Enable for development
)

let sdk = VoiceStreamSDK.initialize(config: config)
```

#### Set Up Event Handlers

```swift
// Connection established
sdk.onConnectedHandler = {
    print("Connected to server")
    sdk.startAudioStreaming()
}

// Audio received from server
sdk.onAudioReceivedHandler = { audioData in
    print("Received audio: \(audioData.count) bytes")
}

// Handle errors
sdk.onErrorHandler = { error in
    print("Error occurred: \(error)")
}

// Disconnection
sdk.onDisconnectedHandler = { reason in
    print("Disconnected: \(reason)")
}
```

#### Connect and Start Streaming

```swift
// Connect to the server
sdk.connect()

// Start audio streaming (call this after connection is established)
// sdk.startAudioStreaming()

// Stop streaming when done
// sdk.stopAudioStreaming()

// Disconnect from server
// sdk.disconnect()
```

## Complete Example

Here's a complete minimal example:

```swift
import SwiftUI
import VoiceStreamSDK

class VoiceStreamManager: ObservableObject {
    @Published var isConnected = false
    @Published var isStreaming = false

    private var sdk: VoiceStreamSDK?

    init() {
        setupSDK()
    }

    private func setupSDK() {
        let config = VoiceStreamConfig(
            serverUrl: "wss://streaming-poc.smartserve.ai/ws",
            tenantId: "demo-tenant",
            tenantName: "Demo App",
            enableDebugLogging: true
        )

        sdk = VoiceStreamSDK.initialize(config: config)

        sdk?.onConnectedHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.isConnected = true
            }
        }

        sdk?.onDisconnectedHandler = { [weak self] reason in
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.isStreaming = false
            }
        }

        sdk?.onErrorHandler = { error in
            print("SDK Error: \(error)")
        }
    }

    func connect() {
        sdk?.connect()
    }

    func startStreaming() {
        sdk?.startAudioStreaming()
        isStreaming = true
    }

    func stopStreaming() {
        sdk?.stopAudioStreaming()
        isStreaming = false
    }

    func disconnect() {
        sdk?.disconnect()
    }
}

struct ContentView: View {
    @StateObject private var manager = VoiceStreamManager()

    var body: some View {
        VStack(spacing: 20) {
            Text(manager.isConnected ? "Connected" : "Disconnected")
                .foregroundColor(manager.isConnected ? .green : .red)

            Button("Connect") {
                manager.connect()
            }
            .disabled(manager.isConnected)

            Button("Start Streaming") {
                manager.startStreaming()
            }
            .disabled(!manager.isConnected || manager.isStreaming)

            Button("Stop Streaming") {
                manager.stopStreaming()
            }
            .disabled(!manager.isStreaming)

            Button("Disconnect") {
                manager.disconnect()
            }
            .disabled(!manager.isConnected)
        }
        .padding()
    }
}
```

## Configuration Options

The `VoiceStreamConfig` struct supports the following parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `serverUrl` | String | `wss://streaming-poc.smartserve.ai/ws` | WebSocket server URL |
| `tenantId` | String | Required | Your tenant identifier |
| `tenantName` | String | Required | Your tenant name |
| `authToken` | String? | `nil` | Optional authentication token |
| `autoReconnect` | Bool | `true` | Enable automatic reconnection |
| `maxReconnectAttempts` | Int | `5` | Maximum reconnection attempts |
| `audioInputSampleRate` | Double | `16000.0` | Microphone sample rate (Hz) |
| `audioOutputSampleRate` | Double | `24000.0` | Speaker sample rate (Hz) |
| `enableDebugLogging` | Bool | `false` | Enable debug logs |

## Next Steps

- **Read the [README](README.md)** for complete API documentation
- **Check the [QUICK_START.md](QUICK_START.md)** for more examples
- **See the [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)** for detailed integration steps
- **Run the Demo App** in the `DemoApp` folder to see a complete working example

## Troubleshooting

### Microphone Permission Issues
- Make sure `NSMicrophoneUsageDescription` is added to Info.plist
- Check Settings → Privacy → Microphone on your device

### Connection Issues
- Verify your server URL is correct
- Check your internet connection
- Enable debug logging to see detailed logs

### Build Issues
- Clean build folder: **⇧⌘K** (Product → Clean Build Folder)
- Update Swift packages: **File → Packages → Update to Latest Package Versions**
- Reset package caches: **File → Packages → Reset Package Caches**

