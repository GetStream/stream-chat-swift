//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic response information
final class GetRepliesResponse: Sendable, Decodable {
    let messages: [MessageResponse]

    init(messages: [MessageResponse]) {
        self.messages = messages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.messages = try container.decodeArrayIgnoringFailures(
            [MessageResponse].self,
            forKey: .messages
        )
    }
}
