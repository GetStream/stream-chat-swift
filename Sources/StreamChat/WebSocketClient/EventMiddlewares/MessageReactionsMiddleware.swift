//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `EventWithReactionPayload` events and updates `MessageReactionDTO` accordingly.
struct MessageReactionsMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    let database: DatabaseContainer
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        guard
            let reactionEvent = event as? EventWithReactionPayload,
            let payload = reactionEvent.payload as? EventPayload<ExtraData>,
            let reaction = payload.reaction
        else {
            completion(event)
            return
        }
        
        database.write({ session in
            if reactionEvent is ReactionNewEvent {
                try session.saveReaction(payload: reaction)
            } else if reactionEvent is ReactionUpdatedEvent {
                try session.saveReaction(payload: reaction)
            } else if reactionEvent is ReactionDeletedEvent {
                guard
                    let dto = session.reaction(
                        messageId: reaction.messageId,
                        userId: reaction.user.id,
                        type: reaction.type
                    )
                else { return }
                
                session.delete(reaction: dto)
            } else {
                throw ClientError.Unexpected("Middleware has tried to handle unsupported event type.")
            }
        }, completion: { error in
            if let error = error {
                log.error("Failed to update message reaction in the database, error: \(error)")
            }
            completion(event)
        })
    }
}
