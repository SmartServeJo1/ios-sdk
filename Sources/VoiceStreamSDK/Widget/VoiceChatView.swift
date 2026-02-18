//
//  VoiceChatView.swift
//  VoiceStreamSDK
//
//  Reusable SwiftUI voice chat widget with FAB and expandable chat panel
//

import SwiftUI

#if canImport(UIKit)
import UIKit

// MARK: - Rounded Corner Shape Helper

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

@available(iOS 15.0, *)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

/// A reusable voice chat widget that overlays on top of your app content
///
/// Usage:
/// ```swift
/// ZStack {
///     YourAppContent()
///     VoiceChatView(config: config, listener: myListener)
/// }
/// ```
@available(iOS 15.0, *)
public struct VoiceChatView: View {
    @StateObject private var viewModel: VoiceChatViewModel

    private let listener: VoiceChatWidgetListener?

    public init(
        config: VoiceStreamConfig,
        theme: VoiceChatTheme = .default,
        listener: VoiceChatWidgetListener? = nil
    ) {
        self.listener = listener
        _viewModel = StateObject(wrappedValue: VoiceChatViewModel(config: config, theme: theme))
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Invisible spacer to fill full screen so .bottomTrailing works
            Color.clear

            // Dim overlay when expanded
            if viewModel.isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.toggleExpanded()
                    }
                    .transition(.opacity)
            }

            if viewModel.isExpanded {
                chatPanel
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3, anchor: .bottomTrailing).combined(with: .opacity),
                        removal: .scale(scale: 0.3, anchor: .bottomTrailing).combined(with: .opacity)
                    ))
            } else {
                fabButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            viewModel.listener = listener
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isExpanded)
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Button(action: { viewModel.toggleExpanded() }) {
            ZStack {
                Circle()
                    .fill(viewModel.theme.primaryColor)
                    .frame(width: viewModel.theme.fabSize, height: viewModel.theme.fabSize)
                    .shadow(color: viewModel.theme.primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "headphones")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 32)
    }

    // MARK: - Chat Panel

    private var chatPanel: some View {
        VStack(spacing: 0) {
            chatHeader
            messageList
            poweredByFooter
            inputBar
        }
        .frame(
            maxWidth: viewModel.theme.panelMaxWidth,
            maxHeight: viewModel.theme.panelMaxHeight
        )
        .background(viewModel.theme.backgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.trailing, 16)
        .padding(.bottom, 32)
    }

    // MARK: - Chat Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "headphones")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Assistant")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isConnected ? viewModel.theme.connectedDotColor : viewModel.theme.disconnectedDotColor)
                        .frame(width: 6, height: 6)
                    Text(viewModel.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
            }

            Spacer()

            Button(action: { viewModel.toggleExpanded() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    viewModel.theme.headerGradientStart,
                    viewModel.theme.headerGradientMid,
                    viewModel.theme.headerGradientEnd
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedCornerShape(radius: 16, corners: [.topLeft, .topRight]))
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        messageView(for: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastId = viewModel.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func messageView(for message: ChatMessage) -> some View {
        switch message.type {
        case .user:
            UserBubbleView(message: message, theme: viewModel.theme)
        case .assistant:
            AssistantBubbleView(message: message, theme: viewModel.theme)
        case .system:
            SystemMessageView(message: message)
        case .thinking:
            ThinkingIndicatorView(theme: viewModel.theme)
        }
    }

    // MARK: - Powered By Footer

    private var poweredByFooter: some View {
        Text("Powered by smartserve.ai")
            .font(.system(size: 10))
            .foregroundColor(Color.gray.opacity(0.6))
            .padding(.vertical, 4)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Type a message...", text: $viewModel.textInput)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "F3F4F6"))
                .cornerRadius(20)
                .onSubmit {
                    viewModel.sendTextMessage()
                }

            if !viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: { viewModel.sendTextMessage() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.theme.primaryColor)
                }
                .transition(.scale.combined(with: .opacity))
            }

            Button(action: { viewModel.toggleMic() }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isStreaming ? viewModel.theme.micActiveColor : viewModel.theme.primaryColor)
                        .frame(width: 36, height: 36)

                    if viewModel.isStreaming {
                        Circle()
                            .stroke(viewModel.theme.micActiveColor.opacity(0.5), lineWidth: 2)
                            .frame(width: 36, height: 36)
                            .scaleEffect(viewModel.isStreaming ? 1.4 : 1.0)
                            .opacity(viewModel.isStreaming ? 0 : 1)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                                value: viewModel.isStreaming
                            )
                    }

                    Image(systemName: viewModel.isStreaming ? "mic.fill" : "mic")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .animation(.easeInOut(duration: 0.2), value: viewModel.textInput.isEmpty)
    }
}

// MARK: - User Bubble

@available(iOS 15.0, *)
struct UserBubbleView: View {
    let message: ChatMessage
    let theme: VoiceChatTheme

    var body: some View {
        HStack {
            Spacer(minLength: 60)
            Text(message.text)
                .font(.system(size: 14))
                .foregroundColor(theme.userTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.userBubbleColor)
                .cornerRadius(16)
                .cornerRadius(4, corners: [.bottomRight])
        }
    }
}

// MARK: - Assistant Bubble

@available(iOS 15.0, *)
struct AssistantBubbleView: View {
    let message: ChatMessage
    let theme: VoiceChatTheme

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ZStack {
                Circle()
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(width: 24, height: 24)
                Text("AI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.primaryColor)
            }

            Text(message.text)
                .font(.system(size: 14))
                .foregroundColor(theme.assistantTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.assistantBubbleColor)
                .cornerRadius(16)
                .cornerRadius(4, corners: [.bottomLeft])

            Spacer(minLength: 60)
        }
    }
}

// MARK: - System Message

@available(iOS 15.0, *)
struct SystemMessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            Spacer()
            Text(message.text)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            Spacer()
        }
    }
}

// MARK: - Thinking Indicator

@available(iOS 15.0, *)
struct ThinkingIndicatorView: View {
    let theme: VoiceChatTheme
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ZStack {
                Circle()
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(width: 24, height: 24)
                Text("AI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.primaryColor)
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(theme.primaryColor.opacity(0.6))
                        .frame(width: 7, height: 7)
                        .offset(y: animating ? -4 : 2)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(theme.assistantBubbleColor)
            .cornerRadius(16)
            .cornerRadius(4, corners: [.bottomLeft])
            .onAppear { animating = true }

            Spacer(minLength: 60)
        }
    }
}

#endif // canImport(UIKit)
