//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a draft message is updated or created.
public final class DraftUpdatedEvent: Event {
    /// The channel identifier of the draft.
    public let cid: ChannelId

    /// The channel object of the draft.
    public let channel: ChatChannel

    /// The draft message.
    public let draftMessage: DraftMessage

    /// The event timestamp.
    public let createdAt: Date

    init(cid: ChannelId, channel: ChatChannel, draftMessage: DraftMessage, createdAt: Date) {
        self.cid = cid
        self.channel = channel
        self.draftMessage = draftMessage
        self.createdAt = createdAt
    }
}

extension DraftUpdatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let draft = draft else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard
            let messageDTO = session.message(id: draft.message.id),
            let channelDTO = session.channel(cid: channelId) else {
            return nil
        }
        return try? DraftUpdatedEvent(
            cid: channelId,
            channel: channelDTO.asModel(),
            draftMessage: DraftMessage(messageDTO.asModel()),
            createdAt: createdAt
        )
    }
}

/// Triggered when a draft message is deleted.
public final class DraftDeletedEvent: Event {
    /// The channel identifier of the draft.
    public let cid: ChannelId

    /// The thread identifier of the draft.
    public let threadId: MessageId?

    /// The event timestamp.
    public let createdAt: Date

    init(cid: ChannelId, threadId: MessageId?, createdAt: Date) {
        self.cid = cid
        self.threadId = threadId
        self.createdAt = createdAt
    }
}

extension DraftDeletedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let channelId = cid.flatMap({ try? ChannelId(cid: $0) }) else { return nil }
        return DraftDeletedEvent(
            cid: channelId,
            threadId: draft?.parentId ?? parentId,
            createdAt: createdAt
        )
    }
}
