// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamChat",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "StreamChat",
            targets: ["StreamChat"]),
        .library(
            name: "StreamChatCore",
            targets: ["StreamChatCore"]),
    ],
    dependencies: [
        // UI
        .package(url: "https://github.com/kean/Nuke.git", from: "8.2.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0"),
        .package(url: "https://github.com/kirualex/SwiftyGif.git", from: "5.1.0"),
        .package(url: "https://github.com/RxSwiftCommunity/RxGesture.git", from: "3.0.0"),
        // Core
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0"),
        .package(url: "https://github.com/GetStream/RxAppState.git", from: "1.6.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.0"),
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", from: "4.3.0"),
        .package(url: "https://github.com/1024jp/GzipSwift.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "StreamChat",
            dependencies: ["StreamChatCore", "Nuke", "SnapKit", "SwiftyGif", "RxGesture"],
            path: "Sources/UI"),
        .target(
            name: "StreamChatCore",
            dependencies: ["RxSwift", "RxAppState", "Starscream", "Reachability", "Gzip"],
            path: "Sources/Core"),
    ]
)
