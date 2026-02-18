# VoiceStreamSDK-iOS

Real-time voice streaming SDK for iOS with built-in AI chat widget. Connects to a voice AI backend via WebSocket for live audio conversation with STT/TTS.

## Installation

### Swift Package Manager (Xcode)

1. In Xcode: **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/karakode-kode/VoiceStreamSDK-iOS.git
   ```
3. Select version rule (e.g., **Up to Next Major**)
4. Click **Add Package**

### Swift Package Manager (Package.swift)

Add to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/karakode-kode/VoiceStreamSDK-iOS.git", from: "1.0.0")
]
```

Then add `"VoiceStreamSDK"` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["VoiceStreamSDK"]
)
```

## Requirements

- iOS 14.0+
- Swift 5.9+
- Microphone permission (`NSMicrophoneUsageDescription` in Info.plist)

## Quick Start

### Option 1: Drop-in Voice Chat Widget (Recommended)

The SDK includes a ready-to-use `VoiceChatView` widget with a floating action button, chat bubbles, mic control, and text input.

```swift
import SwiftUI
import VoiceStreamSDK

struct ContentView: View {
    @StateObject private var listener = MyListener()

    var body: some View {
        ZStack {
            YourAppContent()

            if #available(iOS 15.0, *) {
                VoiceChatView(
                    config: VoiceStreamConfig(
                        serverUrl: "wss://your-server.com/ws",
                        tenantId: "your-tenant",
                        tenantName: "Your App"
                    ),
                    listener: listener
                )
            }
        }
    }
}
```

### Option 2: Direct SDK Usage

For full control over the UI:

```swift
import VoiceStreamSDK

let config = VoiceStreamConfig(
    serverUrl: "wss://your-server.com/ws",
    tenantId: "your-tenant",
    tenantName: "Your App",
    enableDebugLogging: true
)

let sdk = VoiceStreamSDK.initialize(config: config)

sdk.onConnectedHandler = {
    sdk.startAudioStreaming()
}

sdk.onTranscriptHandler = { text, isFinal, language, requiresResponse in
    print("User said: \(text)")
}

sdk.onAssistantMessageHandler = { text in
    print("AI said: \(text)")
}

sdk.connect()
```

## AI Clinic Mode (LLM Delegation)

The SDK supports a delegation pattern where the voice AI handles greetings and small talk, but delegates domain-specific questions to your app's own LLM:

```swift
class MyListener: ObservableObject, VoiceChatWidgetListener {

    func onLlmResponseRequired(question: String, respond: @escaping (String) -> Void) {
        // Send question to your own LLM
        myLLMService.ask(question) { answer in
            respond(answer)  // SDK will speak the answer via TTS
        }
    }

    func onConnectionStateChanged(state: ConnectionState) {
        print("Connection: \(state)")
    }

    func onError(error: VoiceStreamError) {
        print("Error: \(error)")
    }
}
```

**Flow:**
1. User asks a domain question (e.g., "What are your clinic hours?")
2. Voice AI says a filler phrase ("One moment please, let me check...")
3. SDK calls `onLlmResponseRequired` with the user's question
4. Your app sends it to your LLM and calls `respond()` with the answer
5. The voice AI speaks the answer naturally via TTS

## Configuration

```swift
VoiceStreamConfig(
    serverUrl: "wss://your-server.com/ws",  // WebSocket endpoint
    tenantId: "your-tenant",                 // Tenant identifier
    tenantName: "Your App",                  // Display name
    authToken: "optional-jwt",               // Bearer auth (optional)
    autoReconnect: true,                     // Auto-reconnect on disconnect
    maxReconnectAttempts: 5,                 // Max retry attempts
    enableDebugLogging: false,               // Console logging
    audioInputSampleRate: 16000.0,           // Mic capture rate (Hz)
    audioOutputSampleRate: 24000.0           // Speaker playback rate (Hz)
)
```

## Widget Theming

Customize the chat widget appearance:

```swift
let theme = VoiceChatTheme(
    primaryColor: .blue,
    backgroundColor: .white,
    userBubbleColor: Color.blue.opacity(0.15),
    assistantBubbleColor: Color.gray.opacity(0.1),
    fabSize: 56
)

VoiceChatView(config: config, theme: theme, listener: listener)
```

## Callbacks

### Closure-based

```swift
sdk.onConnectedHandler = { }
sdk.onDisconnectedHandler = { reason in }
sdk.onErrorHandler = { error in }
sdk.onTranscriptHandler = { text, isFinal, language, requiresResponse in }
sdk.onAssistantMessageHandler = { text in }
sdk.onLlmRequiredHandler = { question in }
sdk.onReadyHandler = { }
sdk.onInterruptHandler = { }
sdk.onAudioReceivedHandler = { data in }
```

### Protocol-based

Implement `VoiceStreamCallback` for all events:

```swift
class MyHandler: VoiceStreamCallback {
    func onConnected() { }
    func onTranscript(text: String, isFinal: Bool, language: String, requiresResponse: Bool) { }
    func onAssistantMessage(text: String) { }
    func onLlmRequired(question: String) { }
    // ... etc
}

sdk.setCallback(object: myHandler)
```

## Info.plist

Add microphone permission:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for voice conversation</string>
```

For background audio (optional):

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Audio Specs

| Direction | Sample Rate | Format | Channels |
|-----------|-------------|--------|----------|
| Mic → Server | 16 kHz | 16-bit PCM LE | Mono |
| Server → Speaker | 24 kHz | 16-bit PCM LE | Mono |

## License

MIT
