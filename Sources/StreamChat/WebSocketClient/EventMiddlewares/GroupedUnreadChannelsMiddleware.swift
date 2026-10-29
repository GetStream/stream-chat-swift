//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct GroupedUnreadChannelsMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        event
    }

    func handle(event: Event, wsEvent: WSEvent, session: DatabaseSession) -> Event? {
        switch event {
        case let markReadEvent as NotificationMarkReadEventDTO where markReadEvent.isMarkAllRead:
            let filteredQueries = session.loadFilteredGroupChannelListQueries()
            filteredQueries.forEach { $0.groupNotLoadedUnreadCount = 0 }
            session.updateFilteredGroupUnreadChannelCounts(for: filteredQueries)
        case is ChannelDeletedEventDTO, is ChannelHiddenEventDTO, is ChannelTruncatedEventDTO, is ChannelVisibleEventDTO,
             is MessageDeletedEventDTO, is MessageNewEventDTO, is MessageReadEventDTO, is NotificationMarkReadEventDTO,
             is NotificationMarkUnreadEventDTO, is NotificationNewMessageEventDTO:
            guard let cid = wsEvent.commonData.cid, let channelDTO = session.channel(cid: cid) else { break }
            session.updateFilteredGroupUnreadChannelCounts(for: Array(channelDTO.queries))
        default:
            break
        }
        return event
    }
}
