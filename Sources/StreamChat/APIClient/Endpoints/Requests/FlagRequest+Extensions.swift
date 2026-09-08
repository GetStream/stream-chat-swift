//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension FlagRequest {
    /// Flags a chat message.
    ///
    /// The v2 flag endpoint is generic over entity types, so the message is identified by
    /// the `stream:chat:v1:message` entity type instead of a dedicated `target_message_id`
    /// field like in v1.
    convenience init(messageId: MessageId, reason: String?, custom: [String: RawJSON]?) {
        self.init(custom: custom, entityId: messageId, entityType: "stream:chat:v1:message", reason: reason)
    }

    /// Flags a user.
    ///
    /// The v2 flag endpoint is generic over entity types, so the user is identified by
    /// the `stream:user` entity type instead of a dedicated `target_user_id` field like in v1.
    convenience init(userId: UserId, reason: String?, custom: [String: RawJSON]?) {
        self.init(custom: custom, entityId: userId, entityType: "stream:user", reason: reason)
    }
}
