// swift-tools-version:6.0

import Foundation
import PackageDescription

let package = Package(
    name: "StreamChat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13), .macOS(.v11)
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
        .library(
            name: "StreamChatAI",
            targets: ["StreamChatAI"]
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
        .package(url: "https://github.com/GetStream/stream-core-swift.git", from: "0.11.0"),
        .package(url: "https://github.com/JohnSundell/Splash.git", exact: "0.16.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", exact: "2.4.0")
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
                .product(name: "Splash", package: "Splash"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ],
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
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
