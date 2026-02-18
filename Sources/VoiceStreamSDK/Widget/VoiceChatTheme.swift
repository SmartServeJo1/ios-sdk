//
//  VoiceChatTheme.swift
//  VoiceStreamSDK
//
//  Theme configuration for the voice chat widget
//

import SwiftUI

/// Theme configuration for VoiceChatView
public struct VoiceChatTheme {
    public let primaryColor: Color
    public let userBubbleColor: Color
    public let assistantBubbleColor: Color
    public let micActiveColor: Color
    public let headerGradientStart: Color
    public let headerGradientMid: Color
    public let headerGradientEnd: Color
    public let connectedDotColor: Color
    public let disconnectedDotColor: Color
    public let userTextColor: Color
    public let assistantTextColor: Color
    public let backgroundColor: Color
    public let fabSize: CGFloat
    public let panelMaxWidth: CGFloat
    public let panelMaxHeight: CGFloat

    public init(
        primaryColor: Color = Color(hex: "415FAC"),
        userBubbleColor: Color = Color(hex: "415FAC"),
        assistantBubbleColor: Color = Color(hex: "F0F2F5"),
        micActiveColor: Color = Color(hex: "EF4444"),
        headerGradientStart: Color = Color(hex: "3A54A0"),
        headerGradientMid: Color = Color(hex: "4B6ABD"),
        headerGradientEnd: Color = Color(hex: "6B8DE0"),
        connectedDotColor: Color = .green,
        disconnectedDotColor: Color = .red,
        userTextColor: Color = .white,
        assistantTextColor: Color = Color(hex: "1F2937"),
        backgroundColor: Color = .white,
        fabSize: CGFloat = 56,
        panelMaxWidth: CGFloat = 360,
        panelMaxHeight: CGFloat = 520
    ) {
        self.primaryColor = primaryColor
        self.userBubbleColor = userBubbleColor
        self.assistantBubbleColor = assistantBubbleColor
        self.micActiveColor = micActiveColor
        self.headerGradientStart = headerGradientStart
        self.headerGradientMid = headerGradientMid
        self.headerGradientEnd = headerGradientEnd
        self.connectedDotColor = connectedDotColor
        self.disconnectedDotColor = disconnectedDotColor
        self.userTextColor = userTextColor
        self.assistantTextColor = assistantTextColor
        self.backgroundColor = backgroundColor
        self.fabSize = fabSize
        self.panelMaxWidth = panelMaxWidth
        self.panelMaxHeight = panelMaxHeight
    }

    /// Default theme matching the Android widget
    public static var `default`: VoiceChatTheme { VoiceChatTheme() }
}

// MARK: - Color Hex Extension

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
