//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChannelRepository_Mock: ChannelRepository, Spy, @unchecked Sendable {
    let spyState = SpyState()
    var getChannel_store: Bool?
    var getChannel_result: Result<ChatChannel, Error>?
    
    var markReadCid: ChannelId?
    var markReadUserId: UserId?
    var markReadResult: Result<Void, Error>?

    var markUnreadCid: ChannelId?
    var markUnreadUserId: UserId?
    var markUnreadMessageId: UserId?
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

    override func markUnread(for cid: ChannelId, userId: UserId, from messageId: MessageId, lastReadMessageId: MessageId?, completion: ((Result<ChatChannel, Error>) -> Void)? = nil) {
        record()
        markUnreadCid = cid
        markUnreadUserId = userId
        markUnreadMessageId = messageId
        markUnreadLastReadMessageId = lastReadMessageId

        markUnreadResult.map {
            completion?($0)
        }
    }
}
