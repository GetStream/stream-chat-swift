//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelUpdatedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId?
    public let inviteAnswer: InviteAnswer?
    public let updatedAt: Date
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.channel?.cid)
        messageId = response.message?.id
        updatedAt = try response.value(at: \.createdAt)
        payload = response
        
        // Parse InviteAnswer.
        let memberWithInviteAnswer = response.channel?.members?
            .first { $0.user.id == response.user?.id && ($0.inviteAcceptedAt != nil || $0.inviteRejectedAt != nil) }
        
        if let inviteAcceptedAt = memberWithInviteAnswer?.inviteAcceptedAt {
            inviteAnswer = .accepted(at: inviteAcceptedAt)
        } else if let inviteRejectedAt = memberWithInviteAnswer?.inviteRejectedAt {
            inviteAnswer = .rejected(at: inviteRejectedAt)
        } else {
            inviteAnswer = nil
        }
    }
}

public struct ChannelDeletedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    public let deletedAt: Date
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        cid = try response.value(at: \.channel?.cid)
        deletedAt = try response.value(at: \.channel?.deletedAt)
        userId = try response.value(at: \.user?.id)
        payload = response
    }
}

public struct ChannelHiddenEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    public let hiddenAt: Date
    public let isHistoryCleared: Bool
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        hiddenAt = try response.value(at: \.createdAt)
        isHistoryCleared = try response.value(at: \.isChannelHistoryCleared)
        payload = response
    }
}

public struct ChannelTruncatedEvent: EventWithUserPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    let payload: Any

    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

// MARK: - Invite Answer

/// An answer for an invite to join a channel.
/// - accepted: an invite accepted.
/// - rejected: an invite rejected.
public enum InviteAnswer {
    case accepted(at: Date)
    case rejected(at: Date)
}
