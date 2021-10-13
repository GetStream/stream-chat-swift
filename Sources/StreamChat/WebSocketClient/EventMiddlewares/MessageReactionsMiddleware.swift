//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The middleware listens for `EventWithReactionPayload` events and updates `MessageReactionDTO` accordingly.
struct MessageReactionsMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard let context = session as? NSManagedObjectContext else {
            return event
        }

        do {
            switch event {
            case let event as ReactionNewEventDTO:
                guard MessageDTO.load(id: event.reaction.messageId, context: context) != nil else {
                    log.info("Received a reaction event for a message that is not in the database")
                    return event
                }
                try session.saveReaction(payload: event.reaction)
            case let event as ReactionUpdatedEventDTO:
                guard MessageDTO.load(id: event.reaction.messageId, context: context) != nil else {
                    log.info("Received a reaction event for a message that is not in the database")
                    return event
                }
                try session.saveReaction(payload: event.reaction)
            case let event as ReactionDeletedEventDTO:
                guard MessageDTO.load(id: event.reaction.messageId, context: context) != nil else {
                    log.info("Received a reaction event for a message that is not in the database")
                    return event
                }
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
