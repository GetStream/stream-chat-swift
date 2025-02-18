//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a draft message is updated or created.
public struct DraftUpdatedEvent: Event {
    /// The channel identifier of the draft.
    public let cid: ChannelId

    /// The channel object of the draft.
    public let channel: ChatChannel

    /// The draft message.
    public let draftMessage: ChatMessage

    /// The event timestamp.
    public let createdAt: Date
}

class DraftUpdatedEventDTO: EventDTO {
    let cid: ChannelId
    let draft: DraftPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        draft = try response.value(at: \.draft)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let messageDTO = session.message(id: draft.message.id),
            let channelDTO = session.channel(cid: cid) else {
            return nil
        }
        return try? DraftUpdatedEvent(
            cid: cid,
            channel: channelDTO.asModel(),
            draftMessage: messageDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a draft message is deleted.
public struct DraftDeletedEvent: Event {
    /// The channel identifier of the draft.
    public let cid: ChannelId

    /// The thread identifier of the draft.
    public let threadId: MessageId?

    /// The event timestamp.
    public let createdAt: Date
}

class DraftDeletedEventDTO: EventDTO {
    let cid: ChannelId
    let draft: DraftPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        draft = try response.value(at: \.draft)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: any DatabaseSession) -> Event? {
        DraftDeletedEvent(
            cid: cid,
            threadId: draft.parentId,
            createdAt: createdAt
        )
    }
}
