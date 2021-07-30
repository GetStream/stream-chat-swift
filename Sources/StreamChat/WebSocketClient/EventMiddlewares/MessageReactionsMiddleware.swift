//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `EventWithReactionPayload` events and updates `MessageReactionDTO` accordingly.
struct MessageReactionsMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard
            let reactionEvent = event as? ReactionEvent,
            let payload = reactionEvent.payload as? EventPayload,
            let reaction = payload.reaction
        else {
            return event
        }
        
        do {
            if reactionEvent is ReactionNewEvent {
                try session.saveReaction(payload: reaction)
            } else if reactionEvent is ReactionUpdatedEvent {
                try session.saveReaction(payload: reaction)
            } else if reactionEvent is ReactionDeletedEvent {
                if let dto = session.reaction(
                    messageId: reaction.messageId,
                    userId: reaction.user.id,
                    type: reaction.type
                ) {
                    session.delete(reaction: dto)
                }
            } else {
                throw ClientError.Unexpected("Middleware has tried to handle unsupported event type.")
            }
        } catch {
            log.error("Failed to update message reaction in the database, error: \(error)")
        }
        
        return event
    }
}
