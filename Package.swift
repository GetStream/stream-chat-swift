// swift-tools-version:5.2
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
        .library(
            name: "StreamChatClient",
            targets: ["StreamChatClient"]),
    ],
    dependencies: [
        // UI
        .package(url: "https://github.com/kean/Nuke.git", from: "8.4.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0"),
        .package(url: "https://github.com/kirualex/SwiftyGif.git", from: "5.2.0"),
        .package(url: "https://github.com/RxSwiftCommunity/RxGesture.git", from: "4.0.2"),
        // Core
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.2.0"),
        // Client
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "StreamChat",
            dependencies: ["StreamChatCore", "Nuke", "SnapKit", "SwiftyGif", "RxGesture"],
            path: "Sources/UI"),
        .target(
            name: "StreamChatCore",
            dependencies: ["StreamChatClient", "RxSwift", .product(name: "RxCocoa", package: "RxSwift")],
            path: "Sources/Core"),
        .target(
            name: "StreamChatClient",
            dependencies: ["Starscream"],
            path: "Sources/Client")
    ]
)
