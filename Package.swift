// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VoiceStreamSDK",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "VoiceStreamSDK",
            targets: ["VoiceStreamSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "VoiceStreamSDK",
            dependencies: ["Starscream"],
            path: "VoiceStreamSDK/Sources/VoiceStreamSDK"),
        .testTarget(
            name: "VoiceStreamSDKTests",
            dependencies: ["VoiceStreamSDK"],
            path: "VoiceStreamSDK/Tests/VoiceStreamSDKTests"),
    ]
)
