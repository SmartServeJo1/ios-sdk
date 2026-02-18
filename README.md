# VoiceStreamSDK for iOS

Real-time voice AI SDK for iOS. Add a fully working voice assistant to your app in under 5 minutes.

## Step 1: Install the SDK

In Xcode, go to **File > Add Package Dependencies** and enter:

```
https://github.com/SmartServeJo1/ios-sdk.git
```

Select **Up to Next Major Version** from `1.0.0`, then click **Add Package**.

## Step 2: Add Microphone Permission

In your `Info.plist`, add:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for voice conversation</string>
```

## Step 3: Add the Widget

Drop a single line into any SwiftUI view:

```swift
import SwiftUI
import VoiceStreamSDK

struct ContentView: View {
    var body: some View {
        ZStack {
            // Your existing app content
            Text("My App")

            // Voice assistant widget
            if #available(iOS 15.0, *) {
                VoiceChatView(
                    serverUrl: "wss://your-server.com/ws",
                    tenantId: "your-tenant"
                )
            }
        }
    }
}
```

That's it. A floating button appears in the bottom-right corner. Tap it to open the voice chat.

---

## LLM Delegation

If your voice AI delegates questions to your own LLM, pass a closure:

```swift
VoiceChatView(
    serverUrl: "wss://your-server.com/ws",
    tenantId: "clinic"
) { question, respond in
    // Your LLM processes the question
    myLLMService.ask(question) { answer in
        respond(answer)  // Voice AI speaks the answer
    }
}
```

**How it works:**
1. User asks "What are your clinic hours?"
2. Voice AI says "One moment please..."
3. Your closure receives the question
4. You call your LLM, then call `respond()` with the answer
5. Voice AI speaks the answer naturally

---

## Full Control (Listener)

For connection state, error handling, and custom behavior:

```swift
class MyListener: VoiceChatWidgetListener {
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

struct ContentView: View {
    let listener = MyListener()

    var body: some View {
        ZStack {
            YourAppContent()

            if #available(iOS 15.0, *) {
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
}
```

---

## Direct SDK (No Widget)

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

sdk.connect()
```

---

## Theming

Customize colors and sizes to match your app:

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

---

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `serverUrl` | required | WebSocket server URL |
| `tenantId` | required | Tenant identifier |
| `tenantName` | tenantId | Display name |
| `authToken` | nil | Bearer token for auth |
| `autoReconnect` | true | Reconnect on disconnect |
| `maxReconnectAttempts` | 5 | Max retries |
| `enableDebugLogging` | false | Print debug logs |
| `audioInputSampleRate` | 16000 | Mic sample rate (Hz) |
| `audioOutputSampleRate` | 24000 | Speaker sample rate (Hz) |

## Requirements

- iOS 14.0+
- Swift 5.9+

## License

MIT
