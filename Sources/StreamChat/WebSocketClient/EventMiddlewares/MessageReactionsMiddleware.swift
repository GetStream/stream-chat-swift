//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `EventWithReactionPayload` events and updates `MessageReactionDTO` accordingly.
struct MessageReactionsMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let event as ReactionNewEventDTO:
                try session.saveReaction(payload: event.reaction)
                
            case let event as ReactionUpdatedEventDTO:
                try session.saveReaction(payload: event.reaction)
                
            case let event as ReactionDeletedEventDTO:
                if let dto = session.reaction(
                    messageId: event.message.id,
                    userId: event.user.id,
                    type: event.reaction.type
                ) {
                    session.delete(reaction: dto)
                }
            default:
                break
            }
        } catch {
            log.error("Failed to update message reaction in the database, error: \(error)")
        }
        
        return event
    }
}
