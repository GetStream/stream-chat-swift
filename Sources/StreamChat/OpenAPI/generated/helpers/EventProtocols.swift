//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol EventContainsOptionalMessage {
    var message: Message? { get }
    var type: String { get }
    var channelId: String { get }
    var cid: String { get }
}

protocol EventContainsMessage {
    var message: Message { get }
    var type: String { get }
    var channelId: String { get }
    var cid: String { get }
}

protocol EventContainsUser {
    var user: UserObject? { get }
}

protocol EventContainsChannel {
    var channel: ChannelResponse? { get }
}

protocol EventContainsCid {
    var cid: String { get }
}

protocol EventContainsUnreadCount {
    var unreadChannels: Int { get }
    var totalUnreadCount: Int { get }
}

protocol EventContainsCurrentUser {
    var me: OwnUser { get }
}

protocol EventContainsOptionalCurrentUser {
    var me: OwnUser? { get }
}

protocol EventContainsCreationDate {
    var createdAt: Date { get }
}

protocol EventContainsWatchInfo {
    var cid: String { get }
    var user: UserObject? { get }
    var watcherCount: Int { get }
}

extension UserWatchingStartEvent: EventContainsWatchInfo {}
extension UserWatchingStopEvent: EventContainsWatchInfo {}
