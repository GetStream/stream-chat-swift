//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@_exported import StreamChatTestHelpers
import XCTest

extension Bundle {

    private final class StreamChatTestTools {}

    static let bundleName = "StreamChat_StreamChatTestTools"

    private static let JSONs = "JSONs/"
    private static let other = "Other/"

    /// Returns the resource bundle associated with the current Swift module.
    static let testTools: Bundle = {
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: StreamChatTestTools.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        return Bundle(for: StreamChatTestTools.self)
    }()

    var pathToJSONsFolder: String {
        Self.testTools.bundlePath.contains(Self.bundleName) ? Self.JSONs : ""
    }

    var pathToOtherFolder: String {
        Self.testTools.bundlePath.contains(Self.bundleName) ? Self.other : ""
    }
}
