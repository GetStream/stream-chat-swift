// swift-tools-version:5.6

import Foundation
import PackageDescription

let package = Package(
    name: "StreamChat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12), .macOS(.v10_15)
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
            exclude: ["Info.plist"],
            resources: [.process("Fixtures")]
        ),
    ]
)

#if swift(>=5.6)
package.dependencies.append(
    .package(name: "SwiftDocCPlugin", url: "https://github.com/apple/swift-docc-plugin", .exact("1.0.0"))
)
#endif
