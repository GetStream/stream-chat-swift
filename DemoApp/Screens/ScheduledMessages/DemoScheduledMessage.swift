//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

// Mirrors the scheduled message object of the backend spec, so the demo can move to the SDK model once it ships.
struct DemoScheduledMessage: Identifiable, Equatable, Codable {
    enum Status: String, Codable {
        case scheduled
        case sending
        case failed
    }

    enum FailureReason: String, Codable {
        case banned
        case noPermission = "no_permission"
        case channelFrozen = "channel_frozen"
        case channelDeleted = "channel_deleted"
        case userDeleted = "user_deleted"
        case moderationBlocked = "moderation_blocked"
        case hookRejected = "hook_rejected"
        case expired
        case invalidMessage = "invalid_message"
        case internalError = "internal_error"

        var localizedDescription: String {
            switch self {
            case .banned:
                return "You can't send messages in this channel"
            case .noPermission:
                return "You're no longer allowed to post here"
            case .channelFrozen:
                return "This channel is frozen"
            case .channelDeleted:
                return "This channel was deleted"
            case .userDeleted:
                return "Your account was deleted"
            case .moderationBlocked:
                return "Blocked by moderation"
            case .hookRejected:
                return "Rejected by the app"
            case .expired:
                return "Not sent: the service was delayed by more than an hour"
            case .invalidMessage:
                return "The message no longer meets the app's limits. Edit it"
            case .internalError:
                return "Something went wrong. Try again"
            }
        }
    }

    struct Content: Equatable, Codable {
        var text: String
        var attachments: [AnyAttachmentPayload]
        var mentionedUserIds: [UserId]
        var quotedMessageId: MessageId?
        var parentId: MessageId?
        var showReplyInChannel: Bool
        var extraData: [String: RawJSON]

        init(
            text: String,
            attachments: [AnyAttachmentPayload] = [],
            mentionedUserIds: [UserId] = [],
            quotedMessageId: MessageId? = nil,
            parentId: MessageId? = nil,
            showReplyInChannel: Bool = false,
            extraData: [String: RawJSON] = [:]
        ) {
            self.text = text
            self.attachments = attachments
            self.mentionedUserIds = mentionedUserIds
            self.quotedMessageId = quotedMessageId
            self.parentId = parentId
            self.showReplyInChannel = showReplyInChannel
            self.extraData = extraData
        }

        // Attachment payloads are not codable, so they are only kept in memory.
        private enum CodingKeys: String, CodingKey {
            case text
            case mentionedUserIds
            case quotedMessageId
            case parentId
            case showReplyInChannel
            case extraData
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            text = try container.decode(String.self, forKey: .text)
            attachments = []
            mentionedUserIds = try container.decode([UserId].self, forKey: .mentionedUserIds)
            quotedMessageId = try container.decodeIfPresent(MessageId.self, forKey: .quotedMessageId)
            parentId = try container.decodeIfPresent(MessageId.self, forKey: .parentId)
            showReplyInChannel = try container.decode(Bool.self, forKey: .showReplyInChannel)
            extraData = try container.decode([String: RawJSON].self, forKey: .extraData)
        }

        static func == (lhs: Content, rhs: Content) -> Bool {
            lhs.text == rhs.text
                && lhs.mentionedUserIds.sorted() == rhs.mentionedUserIds.sorted()
                && lhs.quotedMessageId == rhs.quotedMessageId
                && lhs.parentId == rhs.parentId
                && lhs.showReplyInChannel == rhs.showReplyInChannel
                && lhs.extraData == rhs.extraData
                && lhs.attachments.map(\.type) == rhs.attachments.map(\.type)
                && lhs.attachments.map(\.localFileURL) == rhs.attachments.map(\.localFileURL)
        }
    }

    let id: String
    let cid: ChannelId
    var content: Content
    var scheduledAt: Date
    var status: Status
    var failureReason: FailureReason?
    let createdAt: Date
    var updatedAt: Date

    var isPending: Bool {
        status != .failed
    }
}

enum DemoScheduledMessageError: LocalizedError {
    case scheduledAtTooSoon
    case scheduledAtTooFar
    case channelLimitReached
    case userLimitReached
    case notFound
    case alreadySending

    var errorDescription: String? {
        switch self {
        case .scheduledAtTooSoon:
            return "Pick a time at least 1 minute from now"
        case .scheduledAtTooFar:
            return "Pick a time within 120 days"
        case .channelLimitReached:
            return "You can schedule up to \(DemoScheduledMessagesService.channelLimit) messages in this channel"
        case .userLimitReached:
            return "You can schedule up to \(DemoScheduledMessagesService.userLimit) messages"
        case .notFound:
            return "This scheduled message no longer exists"
        case .alreadySending:
            return "Already sent"
        }
    }
}
