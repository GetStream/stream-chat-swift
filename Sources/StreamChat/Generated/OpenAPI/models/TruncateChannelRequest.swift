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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case hardDelete = "hard_delete"
        case message
        case skipPush = "skip_push"
    }
}
