# VoiceStreamSDK iOS - Quick Start Guide

Get started with VoiceStreamSDK for iOS in 5 minutes.

## Prerequisites

- Xcode 14.0 or later
- iOS 14.0 or later
- Swift 5.9 or later
- Active internet connection

## Installation

### Option 1: Swift Package Manager (Recommended)

1. Open your project in Xcode
2. Go to **File → Add Packages...**
3. Enter the repository URL or use local package
4. Select version and add to your target

### Option 2: Local Package

1. Drag the `VoiceStreamSDK` folder into your Xcode project
2. In your project settings, go to **General → Frameworks, Libraries, and Embedded Content**
3. Add `VoiceStreamSDK` framework

## Basic Setup

### Step 1: Add Permissions

Add microphone permission to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for voice streaming</string>
```

### Step 2: Import SDK

```swift
import VoiceStreamSDK
```

### Step 3: Initialize SDK

```swift
let config = VoiceStreamConfig(
    serverUrl: "wss://streaming-poc.smartserve.ai/ws",
    tenantId: "your-tenant-id",
    tenantName: "Your Tenant Name",
    enableDebugLogging: true
)

let sdk = VoiceStreamSDK.initialize(config: config)
```

### Step 4: Set Up Callbacks

```swift
// Using closures
sdk.onConnected = {
    print("Connected!")
}

sdk.onAudioReceived = { audioData in
    print("Received \(audioData.count) bytes of audio")
}

sdk.onError = { error in
    print("Error: \(error)")
}

sdk.onDisconnected = { reason in
    print("Disconnected: \(reason)")
}
```

Or implement the protocol:

```swift
class MyViewController: UIViewController, VoiceStreamCallback {
    func onConnected() {
        print("Connected!")
    }

    func onAudioReceived(audioData: Data) {
        print("Received audio")
    }

    // ... other callbacks
}

// Set callback
sdk.setCallback(object: self)
```

### Step 5: Connect and Stream

```swift
// Connect to server
sdk.connect()

// Wait for connection, then start streaming
sdk.onConnected = {
    sdk.startAudioStreaming()
}

// Stop streaming
sdk.stopAudioStreaming()

// Disconnect
sdk.disconnect()

// Cleanup when done
sdk.cleanup()
```

## Complete Example

```swift
import SwiftUI
import VoiceStreamSDK

class VoiceStreamManager: ObservableObject {
    private var sdk: VoiceStreamSDK?

    func setup() {
        let config = VoiceStreamConfig(
            serverUrl: "wss://streaming-poc.smartserve.ai/ws",
            tenantId: "smartserve",
            tenantName: "SmartServe",
            enableDebugLogging: true
        )

        sdk = VoiceStreamSDK.initialize(config: config)

        sdk?.onConnected = {
            print("Connected to server")
        }

        sdk?.onAudioReceived = { audioData in
            print("Received audio: \(audioData.count) bytes")
        }

        sdk?.onError = { error in
            print("Error: \(error)")
        }
    }

    func connect() {
        sdk?.connect()
    }

    func startStreaming() {
        sdk?.startAudioStreaming()
    }

    func stop() {
        sdk?.stopAudioStreaming()
        sdk?.disconnect()
    }
}

struct ContentView: View {
    @StateObject private var manager = VoiceStreamManager()

    var body: some View {
        VStack(spacing: 20) {
            Button("Connect") {
                manager.connect()
            }

            Button("Start Streaming") {
                manager.startStreaming()
            }

            Button("Stop") {
                manager.stop()
            }
        }
        .onAppear {
            manager.setup()
        }
    }
}
```

## SwiftUI Integration

For SwiftUI apps, use `@StateObject` or `@ObservedObject`:

```swift
class StreamViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isStreaming = false

    private var sdk: VoiceStreamSDK?

    init() {
        let config = VoiceStreamConfig(
            tenantId: "your-id",
            tenantName: "Your Name"
        )

        sdk = VoiceStreamSDK.initialize(config: config)

        sdk?.onConnected = { [weak self] in
            DispatchQueue.main.async {
                self?.isConnected = true
            }
        }
    }
}
```

## UIKit Integration

For UIKit apps:

```swift
class ViewController: UIViewController {
    private var sdk: VoiceStreamSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSDK()
    }

    private func setupSDK() {
        let config = VoiceStreamConfig(
            tenantId: "your-id",
            tenantName: "Your Name"
        )

        sdk = VoiceStreamSDK.initialize(config: config)
        sdk?.setCallback(object: self)
    }

    deinit {
        sdk?.cleanup()
    }
}

extension ViewController: VoiceStreamCallback {
    func onConnected() {
        DispatchQueue.main.async {
            // Update UI
        }
    }
}
```

## Common Patterns

### Auto-Start Streaming on Connection

```swift
sdk.onConnected = { [weak self] in
    self?.sdk?.startAudioStreaming()
}
```

### Handle Disconnections

```swift
sdk.onDisconnected = { [weak self] reason in
    print("Disconnected: \(reason)")
    // Auto-reconnection is handled by SDK
}
```

### Error Handling

```swift
sdk.onError = { error in
    switch error {
    case .audioPermissionDenied:
        // Show permission alert
        break
    case .connectionFailed:
        // Show connection error
        break
    default:
        print("Error: \(error)")
    }
}
```

## Testing

Run the included demo app:

1. Open `DemoApp/DemoApp.xcodeproj` in Xcode
2. Select a device or simulator
3. Build and run (⌘R)
4. Grant microphone permission when prompted
5. Tap "Connect" then "Start Streaming"

## Next Steps

- Read the full [README.md](README.md) for detailed API reference
- Check out the [DemoApp](DemoApp/) for a complete implementation
- Configure audio settings in `VoiceStreamConfig`
- Implement custom callbacks for your use case

## Troubleshooting

**SDK not initializing?**
- Make sure you call `initialize()` before using the SDK

**No audio?**
- Check microphone permissions in Settings
- Ensure `startAudioStreaming()` is called after connection
- Verify device volume is not muted

**Connection fails?**
- Check internet connectivity
- Verify server URL is correct
- Check if authentication token is required

**Build errors?**
- Ensure Xcode 14.0+ and iOS 14.0+ deployment target
- Clean build folder (⇧⌘K) and rebuild

## Support

For more help, check the full documentation or open an issue on GitHub.
