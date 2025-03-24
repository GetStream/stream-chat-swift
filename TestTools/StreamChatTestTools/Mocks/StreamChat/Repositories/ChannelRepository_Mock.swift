//
//  ChannelRepository_Mock.swift
//  StreamChatTestTools
//
//  Created by Pol Quintana on 1/3/23.
//  Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

class ChannelRepository_Mock: ChannelRepository, Spy, @unchecked Sendable {
    let spyState = SpyState()
    @Atomic var getChannel_store: Bool?
    @Atomic var getChannel_result: Result<ChatChannel, Error>?
    
    @Atomic var markReadCid: ChannelId?
    @Atomic var markReadUserId: UserId?
    @Atomic var markReadResult: Result<Void, Error>?

    @Atomic var markUnreadCid: ChannelId?
    @Atomic var markUnreadUserId: UserId?
    @Atomic var markUnreadMessageId: UserId?
    @Atomic var markUnreadLastReadMessageId: UserId?
    @Atomic var markUnreadResult: Result<ChatChannel, Error>?

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
