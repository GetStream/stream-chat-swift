//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a thread is updated
public struct ThreadUpdatedEvent: Event {
    /// The updated user
    public let thread: ChatThread

    /// The event timestamp
    public let createdAt: Date?
}

class ThreadUpdatedEventDTO: EventDTO {
    let thread: ThreadPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        thread = try response.value(at: \.thread)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let threadDTO = session.thread(parentMessageId: thread.parentMessageId, cache: nil) else { return nil }

        return try? ThreadUpdatedEvent(
            thread: threadDTO.asModel(),
            createdAt: createdAt
        )
    }
}
