//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct GroupedUnreadChannelsMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        event
    }

    func handle(event: Event, wsEvent: WSEvent, session: DatabaseSession) -> Event? {
        if let markReadEvent = event as? NotificationMarkReadEventDTO, markReadEvent.isMarkAllRead {
            let filteredQueries = session.loadAllChannelListQueries().filter { $0.groupFilterJSONData != nil }
            filteredQueries.forEach { $0.groupNotLoadedUnreadCount = 0 }
            session.updateFilteredGroupUnreadChannelCounts(for: filteredQueries)
        } else if Self.affectsUnreadState(event), let cid = wsEvent.commonData.cid, let channelDTO = session.channel(cid: cid) {
            session.updateFilteredGroupUnreadChannelCounts(for: Array(channelDTO.queries))
        }
        return event
    }

    private static func affectsUnreadState(_ event: Event) -> Bool {
        switch event {
        case is ChannelDeletedEventDTO, is ChannelHiddenEventDTO, is ChannelTruncatedEventDTO, is ChannelVisibleEventDTO,
             is MessageDeletedEventDTO, is MessageNewEventDTO, is MessageReadEventDTO, is NotificationMarkReadEventDTO,
             is NotificationMarkUnreadEventDTO, is NotificationNewMessageEventDTO:
            return true
        default:
            return false
        }
    }
}
