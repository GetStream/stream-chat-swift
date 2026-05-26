//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct DraftUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as DraftUpdatedEventDTO:
            guard let draft = event.draft else { break }
            guard let cidString = event.cid, let channelId = try? ChannelId(cid: cidString) else { break }
            do {
                try session.saveDraftMessage(payload: draft, for: channelId, cache: nil)
            } catch {
                log.error("Failed to save draft message: \(error)")
            }
        case let event as DraftDeletedEventDTO:
            guard let cidString = event.cid, let channelId = try? ChannelId(cid: cidString) else { break }
            let threadId = event.draft?.parentId ?? event.parentId
            session.deleteDraftMessage(in: channelId, threadId: threadId)
        default:
            break
        }
        return event
    }
}
