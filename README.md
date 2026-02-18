# VoiceStreamSDK for iOS

Real-time voice AI SDK for iOS. Drop a widget into your app and get a fully working voice assistant with one line of code.

## Installation

In Xcode: **File > Add Package Dependencies...** and enter:

```
https://github.com/SmartServeJo1/ios-sdk.git
```

Add microphone permission to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for voice conversation</string>
```

## Quick Start

### Basic — Voice assistant in one line

```swift
import SwiftUI
import VoiceStreamSDK

struct ContentView: View {
    var body: some View {
        ZStack {
            YourAppContent()

            VoiceChatView(serverUrl: "wss://your-server.com/ws", tenantId: "your-tenant")
        }
    }
}
```

That's it. A floating button appears in the bottom-right corner. Tap it to open a chat panel with voice and text input.

### With LLM Delegation

If your voice AI delegates questions to your own LLM, pass a closure:

```swift
VoiceChatView(serverUrl: "wss://your-server.com/ws", tenantId: "clinic") { question, respond in
    // Your LLM processes the question
    myLLMService.ask(question) { answer in
        respond(answer) // Voice AI speaks the answer
    }
}
```

**How it works:**
1. User asks "What are your clinic hours?"
2. Voice AI says "One moment please, let me check..."
3. Your closure receives the question
4. You call your LLM, then call `respond()` with the answer
5. Voice AI speaks it naturally

### With Full Control (Listener)

For connection state, error handling, and more:

```swift
struct ContentView: View {
    @StateObject private var listener = MyListener()

    var body: some View {
        ZStack {
            YourAppContent()

            VoiceChatView(
                config: VoiceStreamConfig(
                    serverUrl: "wss://your-server.com/ws",
                    tenantId: "clinic",
                    tenantName: "My Clinic"
                ),
                listener: listener
            )
        }
    }
}

class MyListener: ObservableObject, VoiceChatWidgetListener {
    func onLlmResponseRequired(question: String, respond: @escaping (String) -> Void) {
        myLLM.ask(question) { answer in respond(answer) }
    }

    func onConnectionStateChanged(state: ConnectionState) {
        print("State: \(state)")
    }

    func onError(error: VoiceStreamError) {
        print("Error: \(error)")
    }
}
```

### Direct SDK (No Widget)

For apps that build their own UI:

```swift
import VoiceStreamSDK

let sdk = VoiceStreamSDK.initialize(config: VoiceStreamConfig(
    serverUrl: "wss://your-server.com/ws",
    tenantId: "your-tenant",
    tenantName: "Your App"
))

sdk.onConnectedHandler = { sdk.startAudioStreaming() }
sdk.onTranscriptHandler = { text, _, _, _ in print("User: \(text)") }
sdk.onAssistantMessageHandler = { text in print("AI: \(text)") }
sdk.onLlmRequiredHandler = { question in /* handle delegation */ }

sdk.connect()
```

## Theming

```swift
VoiceChatView(
    serverUrl: "wss://your-server.com/ws",
    tenantId: "clinic",
    theme: VoiceChatTheme(
        primaryColor: Color(hex: "1E3A5F"),
        userBubbleColor: Color.blue.opacity(0.15),
        assistantBubbleColor: Color.gray.opacity(0.08),
        fabSize: 56
    )
)
```

## Configuration Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `serverUrl` | required | WebSocket server URL |
| `tenantId` | required | Tenant identifier |
| `tenantName` | tenantId | Display name |
| `authToken` | nil | Bearer token for auth |
| `autoReconnect` | true | Reconnect on disconnect |
| `maxReconnectAttempts` | 5 | Max retries (0 = unlimited) |
| `enableDebugLogging` | false | Print debug logs |
| `audioInputSampleRate` | 16000 | Mic sample rate (Hz) |
| `audioOutputSampleRate` | 24000 | Speaker sample rate (Hz) |

## Requirements

- iOS 14.0+
- Swift 5.9+

## License

MIT
