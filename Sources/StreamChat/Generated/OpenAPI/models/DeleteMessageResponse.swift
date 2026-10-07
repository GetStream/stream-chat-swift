//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic response information
final class DeleteMessageResponse: Sendable, Decodable {
    /// Represents any chat message
    let message: MessageResponse

    init(message: MessageResponse) {
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.message = try container.decode(MessageResponse.self, forKey: .message)
    }
}
