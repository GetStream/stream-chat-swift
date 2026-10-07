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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(clearHistory, forKey: .clearHistory)
    }
}
