//
//  ChannelRepository_Mock.swift
//  StreamChatTestTools
//
//  Created by Pol Quintana on 1/3/23.
//  Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

class ChannelRepository_Mock: ChannelRepository, Spy {
    let spyState = SpyState()
    var getChannel_store: Bool?
    var getChannel_result: Result<ChatChannel, Error>?
    var getLocalChannel_cid: ChannelId?
    var getLocalChannel_result: Result<ChatChannel?, Error>?
    
    var markReadCid: ChannelId?
    var markReadUserId: UserId?
    var markReadResult: Result<Void, Error>?

    var markUnreadCid: ChannelId?
    var markUnreadUserId: UserId?
    var markUnreadMessageId: UserId?
    var markUnreadLastReadMessageId: UserId?
    var markUnreadResult: Result<ChatChannel, Error>?

    override func getLocalChannel(for cid: ChannelId, completion: @escaping (Result<ChatChannel?, any Error>) -> Void) {
        record()
        getLocalChannel_cid = cid
        getLocalChannel_result?.invoke(with: completion)
    }
    
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
