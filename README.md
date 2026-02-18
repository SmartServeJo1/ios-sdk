# VoiceStreamSDK for iOS

A real-time bidirectional voice streaming SDK for iOS. Connects to a voice AI backend via WebSocket, handles microphone capture, audio playback, and provides a drop-in chat widget with voice and text support.

## Features

- Real-time audio streaming (16kHz capture, 24kHz playback)
- Drop-in `VoiceChatView` widget — FAB button, chat bubbles, mic toggle, text input
- LLM delegation — voice AI handles greetings, your app's LLM handles domain questions
- Auto-reconnect with exponential backoff
- Echo prevention (mic muting during AI playback)
- Customizable theme and colors
- Protocol and closure-based callbacks
- iOS 14+, Swift 5.9+

## Installation

### Swift Package Manager

In Xcode: **File > Add Package Dependencies...** and enter:

```
https://github.com/SmartServeJo1/ios-sdk.git
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SmartServeJo1/ios-sdk.git", from: "1.0.0")
]
```

### Info.plist

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for voice conversation</string>
```

## Usage

### Drop-in Widget

Add `VoiceChatView` as an overlay on any screen. It shows a floating button that expands into a full chat panel with voice and text input.

```swift
import SwiftUI
import VoiceStreamSDK

struct ContentView: View {
    @StateObject private var listener = MyListener()

    var body: some View {
        ZStack {
            // Your existing app content
            YourAppContent()

            // Voice chat widget overlay
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

### Direct SDK Usage

For apps that need full control over the UI:

```swift
import VoiceStreamSDK

let sdk = VoiceStreamSDK.initialize(config: VoiceStreamConfig(
    serverUrl: "wss://your-server.com/ws",
    tenantId: "your-tenant",
    tenantName: "Your App",
    enableDebugLogging: true
))

// Connection
sdk.onConnectedHandler = { sdk.startAudioStreaming() }
sdk.onDisconnectedHandler = { reason in print("Disconnected: \(reason)") }
sdk.onErrorHandler = { error in print("Error: \(error)") }

// Transcripts & AI responses
sdk.onTranscriptHandler = { text, isFinal, language, requiresResponse in
    print("User: \(text)")
}
sdk.onAssistantMessageHandler = { text in
    print("AI: \(text)")
}

// Audio
sdk.onAudioReceivedHandler = { data in /* raw audio from server */ }
sdk.onInterruptHandler = { /* user interrupted AI */ }
sdk.onReadyHandler = { /* AI session ready, greeting will follow */ }

sdk.connect()
```

### Lifecycle

```swift
sdk.connect()              // Connect to server
sdk.startAudioStreaming()  // Start mic + speaker
sdk.stopAudioStreaming()   // Stop mic + speaker
sdk.disconnect()           // Disconnect
sdk.cleanup()              // Release all resources
```

## LLM Delegation

The voice AI handles greetings and small talk directly. For domain-specific questions (medical, booking, etc.), it says a filler phrase and delegates to your app's LLM.

```swift
class MyListener: ObservableObject, VoiceChatWidgetListener {

    func onLlmResponseRequired(question: String, respond: @escaping (String) -> Void) {
        // Your LLM processes the question
        myLLMService.ask(question) { answer in
            respond(answer) // Voice AI speaks the answer
        }
    }

    func onConnectionStateChanged(state: ConnectionState) { }
    func onError(error: VoiceStreamError) { }
}
```

**How it works:**

1. User asks "What are your clinic hours?"
2. Voice AI says "One moment please, let me check that for you"
3. SDK calls `onLlmResponseRequired(question:respond:)`
4. Your app calls its own LLM, then calls `respond("We're open 8am-6pm...")`
5. Voice AI speaks the response naturally

## Configuration

```swift
VoiceStreamConfig(
    serverUrl: "wss://your-server.com/ws",   // WebSocket endpoint
    tenantId: "your-tenant",                  // Tenant ID
    tenantName: "Your App",                   // Display name
    authToken: nil,                           // Optional Bearer token
    autoReconnect: true,                      // Reconnect on disconnect
    maxReconnectAttempts: 5,                  // 0 = unlimited
    reconnectDelayMs: 1000,                   // Initial delay (exponential backoff)
    maxReconnectDelayMs: 30000,               // Max backoff delay
    pingIntervalMs: 30000,                    // Keep-alive interval
    enableDebugLogging: false,                // Console logging
    audioInputSampleRate: 16000.0,            // Mic sample rate
    audioOutputSampleRate: 24000.0            // Speaker sample rate
)
```

## Theming

```swift
VoiceChatView(
    config: config,
    theme: VoiceChatTheme(
        primaryColor: Color(hex: "1E3A5F"),
        backgroundColor: .white,
        userBubbleColor: Color.blue.opacity(0.15),
        assistantBubbleColor: Color.gray.opacity(0.08),
        headerGradientStart: Color(hex: "1E3A5F"),
        headerGradientEnd: Color(hex: "4A90C4"),
        fabSize: 56
    ),
    listener: listener
)
```

## Architecture

```
┌──────────────────────────────────────────┐
│            Your Application              │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│     VoiceChatView (SwiftUI Widget)       │
│  FAB button, chat bubbles, input bar     │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│       VoiceStreamSDK (Singleton)         │
│  Callbacks, lifecycle, state             │
├──────────┬───────────┬───────────────────┤
│ WebSocket│  Audio    │   Audio           │
│ Manager  │ Capture   │  Playback         │
│(Starscream)│(16kHz mic)│(24kHz speaker)  │
└──────────┴───────────┴───────────────────┘
               │
               ▼
        Voice AI Server
    (Gemini Live STT/TTS)
```

## Audio Specs

| Direction | Sample Rate | Format | Channels |
|-----------|-------------|--------|----------|
| Mic to Server | 16 kHz | 16-bit PCM LE | Mono |
| Server to Speaker | 24 kHz | 16-bit PCM LE | Mono |

## License

MIT
