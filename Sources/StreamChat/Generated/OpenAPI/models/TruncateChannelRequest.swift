//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TruncateChannelRequest: Sendable, Encodable, JSONEncodable {
    /// Permanently delete channel data (messages, reactions, etc.)
    let hardDelete: Bool?
    /// Message data for creating or updating a message
    let message: MessageRequest?
    /// When `message` is set disables all push notifications for it
    let skipPush: Bool?

    init(hardDelete: Bool? = nil, message: MessageRequest? = nil, skipPush: Bool? = nil) {
        self.hardDelete = hardDelete
        self.message = message
        self.skipPush = skipPush
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(hardDelete, forKey: .hardDelete)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(skipPush, forKey: .skipPush)
    }
}
