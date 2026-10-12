//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetPinnedMessagesResponse: Sendable, Decodable {
    /// Messages
    let messages: [MessageResponse]

    init(messages: [MessageResponse]) {
        self.messages = messages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.messages = try container.decode([MessageResponse].self, forKey: .messages)
    }
}
