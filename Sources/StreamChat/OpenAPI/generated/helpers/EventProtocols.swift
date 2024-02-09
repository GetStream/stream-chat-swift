//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol EventContainsMessage {
    var message: StreamChatMessage? { get }
    var type: String { get }
    var channelId: String { get }
    var cid: String { get }
}

protocol EventContainsUser {
    var user: StreamChatUserObject? { get }
}

protocol EventContainsChannel {
    var channel: StreamChatChannelResponse? { get }
}

protocol EventContainsUnreadCount {
    var unreadChannels: Int { get }
    var totalUnreadCount: Int { get }
}

protocol EventContainsCurrentUser {
    var me: StreamChatOwnUser? { get }
}

protocol EventContainsCreationDate {
    var createdAt: Date { get }
}

protocol EventContainsWatchInfo {
    var cid: String { get }
    var user: StreamChatUserObject? { get }
    var watcherCount: Int? { get }
}

extension StreamChatUserWatchingStartEvent: EventContainsWatchInfo {}
extension StreamChatUserWatchingStopEvent: EventContainsWatchInfo {}
