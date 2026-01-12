//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct DraftUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as DraftUpdatedEventDTO:
            guard let draft = event.payload.draft else { break }
            do {
                try session.saveDraftMessage(payload: draft, for: event.cid, cache: nil)
            } catch {
                log.error("Failed to save draft message: \(error)")
            }
        case let event as DraftDeletedEventDTO:
            let threadId = event.payload.draft?.parentId
            session.deleteDraftMessage(in: event.cid, threadId: threadId)
        default:
            break
        }
        return event
    }
}
