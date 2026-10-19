//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message scheduled to be sent later
final class ScheduledMessageResponse: Sendable, Decodable {
    /// The channel of a scheduled message
    let channel: ScheduledMessageChannelResponse?
    /// The CID of the channel the message will be sent to
    let cid: String
    /// Date/time of creation
    let createdAt: Date
    /// Why sending the message failed. Only set when status is failed. One of: banned, no_permission, channel_frozen, channel_deleted, user_deleted, moderation_blocked, hook_rejected, expired, internal_error, invalid_message, pending_not_supported
    let failureReason: String?
    /// Unique identifier of the scheduled message
    let id: String
    /// The message a scheduled message will send
    let message: ScheduledMessageContentResponse
    /// Date/time the message is scheduled to be sent
    let scheduledAt: Date
    /// Status of the scheduled message. One of: scheduled, sending, failed, canceled, sent
    let status: String
    /// Date/time of the last update
    let updatedAt: Date
    /// User response object
    let user: UserPayload

    init(
        channel: ScheduledMessageChannelResponse? = nil,
        cid: String,
        createdAt: Date,
        failureReason: String? = nil,
        id: String,
        message: ScheduledMessageContentResponse,
        scheduledAt: Date,
        status: String,
        updatedAt: Date,
        user: UserPayload
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.failureReason = failureReason
        self.id = id
        self.message = message
        self.scheduledAt = scheduledAt
        self.status = status
        self.updatedAt = updatedAt
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(
            ScheduledMessageChannelResponse.self,
            forKey: .channel
        )
        self.cid = try container.decode(String.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.failureReason = try container.decodeIfPresent(String.self, forKey: .failureReason)
        self.id = try container.decode(String.self, forKey: .id)
        self.message = try container.decode(ScheduledMessageContentResponse.self, forKey: .message)
        self.scheduledAt = try container.decode(Date.self, forKey: .scheduledAt)
        self.status = try container.decode(String.self, forKey: .status)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}
