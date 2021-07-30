//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelUpdatedEvent: ChannelSpecificEvent {
    public let cid: ChannelId

    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct ChannelDeletedEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    public let deletedAt: Date
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        deletedAt = try response.value(at: \.channel?.deletedAt)
        payload = response
    }
}

public struct ChannelTruncatedEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct ChannelVisibleEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    let payload: Any

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct ChannelHiddenEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    public let hiddenAt: Date
    public let isHistoryCleared: Bool
    let payload: Any

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        hiddenAt = try response.value(at: \.createdAt)
        isHistoryCleared = try response.value(at: \.isChannelHistoryCleared)
        payload = response
    }
}
