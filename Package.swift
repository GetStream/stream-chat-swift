// swift-tools-version:5.3
// When used via SPM the minimum Swift version is 5.3 because we need support for resources

import Foundation
import PackageDescription

let package = Package(
    name: "StreamChat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11), .macOS(.v10_15)
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
            name: "StreamChatTestTools",
            targets: ["StreamChatTestTools"]
        ),
        .library(
            name: "StreamChatTestMockServer",
            targets: ["StreamChatTestMockServer"]
        ),
    ],
    dependencies: [
        .package(name: "StreamChatTestHelpers", url: "https://github.com/GetStream/stream-chat-swift-test-helpers.git", .exact("0.2.0")),
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter", .exact("1.5.0"))
    ],
    targets: [
        .target(
            name: "StreamChat",
            exclude: ["Info.plist"],
            resources: [.copy("Database/StreamChatModel.xcdatamodeld")]
        ),
        .target(
            name: "StreamChatUI",
            dependencies: ["StreamChat"],
            exclude: ["Info.plist", "Generated/L10n_template.stencil"],
            resources: [.process("Resources")]
        ),
        .target(name: "StreamChatTestTools",
                dependencies: [
                    .target(name: "StreamChat"),
                    .product(name: "StreamChatTestHelpers", package: "StreamChatTestHelpers"),
                ],
                path: "TestTools/StreamChatTestTools",
                exclude: ["Info.plist"],
                resources: [
                        .copy("Fixtures/JSONs"),
                        .copy("Fixtures/Other"),
                        .process("Fixtures/Images")
                ]
        ),
        .target(name: "StreamChatTestMockServer",
                dependencies: [
                    .target(name: "StreamChat"),
                    .product(name: "StreamChatTestHelpers", package: "StreamChatTestHelpers"),
                    .product(name: "Swifter", package: "Swifter")
                ],
                path: "TestTools/StreamChatTestMockServer",
                exclude: ["Info.plist"],
                resources: [.copy("Fixtures")]
        ),
    ]
)

#if swift(>=5.6)
package.dependencies.append(
    .package(name: "SwiftDocCPlugin", url: "https://github.com/apple/swift-docc-plugin", .exact("1.0.0"))
)
#endif
