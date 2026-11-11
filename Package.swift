// swift-tools-version:6.0

import Foundation
import PackageDescription

let package = Package(
    name: "StreamChat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13), .macOS(.v11), .tvOS(.v15)
    ],
    products: [
        .library(
            name: "StreamChat",
            targets: ["StreamChat"]
        ),
        .library(
            name: "StreamChatUI",
            targets: ["StreamChatUI"]
        ),
        .library(
            name: "StreamChatCommonUI",
            targets: ["StreamChatCommonUI"]
        ),
        // In-app log viewer, meant for demo apps and debug builds only
        .library(
            name: "StreamChatLogsUI",
            targets: ["StreamChatLogsUI"]
        ),
        .library(
            name: "StreamChatAI",
            targets: ["StreamChatAI"]
        ),
        .library(
            name: "StreamChatA2UI",
            targets: ["StreamChatA2UI"]
        ),
        .library(
            name: "StreamChatOpenUI",
            targets: ["StreamChatOpenUI"]
        ),
        .library(
            name: "StreamChatTestTools",
            targets: ["StreamChatTestTools"]
        ),
        .library(
            name: "StreamChatTestMockServer",
            targets: ["StreamChatTestMockServer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", exact: "1.0.0"),
        .package(url: "https://github.com/GetStream/stream-core-swift.git", from: "0.18.0"),
        .package(url: "https://github.com/GetStream/stream-logs-ui-swift.git", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "StreamChat",
            dependencies: [
                .product(name: "StreamCore", package: "stream-core-swift")
            ],
            exclude: ["Info.plist", "Generated/OpenAPIDecodable.stencil", "Generated/PredefinedFilter.stencil"],
            resources: [.process("Database/StreamChatModel.xcdatamodeld")]
        ),
        .target(
            name: "StreamChatUI",
            dependencies: ["StreamChat", "StreamChatCommonUI"],
            exclude: ["Info.plist"]
        ),
        .target(
            name: "StreamChatCommonUI",
            dependencies: ["StreamChat"],
            exclude: ["Info.plist", "Generated/L10n_template.stencil"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "StreamChatAI",
            dependencies: [
                .product(name: "StreamCore", package: "stream-core-swift"),
                .product(name: "StreamCoreUI", package: "stream-core-swift"),
                "StreamChatAICMark"
            ],
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        ),
        // cmark-gfm from swift-markdown-ui, which StreamChatAI embeds
        .target(name: "StreamChatAICMark"),
        // The A2UI renderer, and the AIUIRenderer that shows it in StreamChatAI's generated UI
        .target(
            name: "StreamChatA2UI",
            dependencies: ["StreamChatAI"],
            exclude: ["Info.plist"]
        ),
        // The OpenUI Lang renderer, and the renderer of StreamChatAI's generated UI built on it
        .target(
            name: "StreamChatOpenUI",
            dependencies: ["StreamChatAI"],
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "StreamChatLogsUI",
            dependencies: [
                "StreamChat",
                .product(name: "StreamLogsUI", package: "stream-logs-ui-swift")
            ]
        ),
        .target(
            name: "StreamChatTestTools",
            dependencies: ["StreamChat"],
            path: "TestTools/StreamChatTestTools",
            exclude: ["Info.plist"],
            resources: [.process("Fixtures")]
        ),
        .target(
            name: "StreamChatTestMockServer",
            dependencies: ["StreamChat"],
            path: "TestTools/StreamChatTestMockServer",
            exclude: ["Info.plist"]
        )
    ]
)
