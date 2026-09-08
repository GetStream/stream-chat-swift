//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class HideChannelRequest: Sendable, Encodable, JSONEncodable {
    /// Whether to clear message history of the channel or not
    let clearHistory: Bool?

    init(clearHistory: Bool? = nil) {
        self.clearHistory = clearHistory
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case clearHistory = "clear_history"
    }
}
