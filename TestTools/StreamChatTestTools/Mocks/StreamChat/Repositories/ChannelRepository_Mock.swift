//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChannelRepository_Mock: ChannelRepository, Spy {
    let spyState = SpyState()
    var getChannel_store: Bool?
    var getChannel_result: Result<ChatChannel, Error>?
    
    var markReadCid: ChannelId?
    var markReadUserId: UserId?
    var markReadResult: Result<Void, Error>?

    var markUnreadCid: ChannelId?
    var markUnreadUserId: UserId?
    var markUnreadCriteria: MarkUnreadCriteria?
    var markUnreadLastReadMessageId: UserId?
    var markUnreadResult: Result<ChatChannel, Error>?

    override func getChannel(for query: ChannelQuery, store: Bool, completion: @escaping (Result<ChatChannel, any Error>) -> Void) {
        record()
        getChannel_store = store
        getChannel_result?.invoke(with: completion)
    }
    
    override func markRead(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        record()
        markReadCid = cid
        markReadUserId = userId

        markReadResult.map {
            completion?($0.error)
        }
    }

    override func markUnread(for cid: ChannelId, userId: UserId, from unreadCriteria: MarkUnreadCriteria, lastReadMessageId: MessageId?, completion: ((Result<ChatChannel, any Error>) -> Void)? = nil) {
        record()
        markUnreadCid = cid
        markUnreadUserId = userId
        markUnreadCriteria = unreadCriteria
        markUnreadLastReadMessageId = lastReadMessageId

        markUnreadResult.map {
            completion?($0)
        }
    }
}
