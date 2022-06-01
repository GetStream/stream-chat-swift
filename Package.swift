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
        )
    ],
    targets: [
        .target(
            name: "StreamChat",
            exclude: ["README.md", "Info.plist", "StreamChat.docc"],
            resources: [.copy("Database/StreamChatModel.xcdatamodeld")]
        ),
        .target(
            name: "StreamChatUI",
            dependencies: ["StreamChat"],
            exclude: ["README.md", "Info.plist", "Generated/L10n_template.stencil", "StreamChatUI.docc"],
            resources: [.process("Resources")]
        )
    ]
)

#if swift(>=5.6)
package.dependencies.append(
    .package(name: "SwiftDocCPlugin", url: "https://github.com/apple/swift-docc-plugin", .exact("1.0.0"))
)
#endif
