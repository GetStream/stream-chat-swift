//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

enum DemoScheduledMessageLimits {
    static let minimumLeadTime: TimeInterval = 60
    static let maximumLeadTime: TimeInterval = 120 * 24 * 60 * 60
}

// What the composer schedules, compared with what it started editing to save only real changes.
struct DemoScheduledMessageContent: Equatable {
    var text: String
    var attachments: [AnyAttachmentPayload]
    var mentionedUserIds: [UserId]
    var quotedMessageId: MessageId?
    var parentId: MessageId?
    var showReplyInChannel: Bool
    var extraData: [String: RawJSON]

    static func == (lhs: Self, rhs: Self) -> Bool {
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

extension ScheduledMessageError.PublishingFailure.Reason {
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
        default:
            return "Something went wrong. Try again"
        }
    }
}
