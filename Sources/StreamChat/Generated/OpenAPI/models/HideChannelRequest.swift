//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class HideChannelRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Whether to clear message history of the channel or not
    var clearHistory: Bool?

    init(clearHistory: Bool? = nil) {
        self.clearHistory = clearHistory
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case clearHistory = "clear_history"
    }

    static func == (lhs: HideChannelRequest, rhs: HideChannelRequest) -> Bool {
        lhs.clearHistory == rhs.clearHistory
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(clearHistory)
    }
}
