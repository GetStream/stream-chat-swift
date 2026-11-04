//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// The model writes every link, so only the schemes react-markdown keeps by default for web links
// and email open; a link to another app or a phone number doesn't.
@available(iOS 17.0, macOS 14.0, *)
enum OpenUILink {
    static let schemes: Set<String> = ["http", "https", "mailto"]

    static func isOpenable(_ url: URL) -> Bool {
        schemes.contains(url.scheme?.lowercased() ?? "")
    }
}
