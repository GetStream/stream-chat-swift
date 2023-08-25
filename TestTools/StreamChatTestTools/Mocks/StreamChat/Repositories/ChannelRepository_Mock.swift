//
//  ChannelRepository_Mock.swift
//  StreamChatTestTools
//
//  Created by Pol Quintana on 1/3/23.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

class ChannelRepository_Mock: ChannelRepository {
    var markReadCid: ChannelId?
    var markReadUserId: UserId?
    var markReadResult: Result<Void, Error>?

    var markUnreadCid: ChannelId?
    var markUnreadUserId: UserId?
    var markUnreadMessageId: UserId?
    var markUnreadLastReadMessageId: UserId?
    var markUnreadResult: Result<Void, Error>?

    override func markRead(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        markReadCid = cid
        markReadUserId = userId

        markReadResult.map {
            completion?($0.error)
        }
    }

    override func markUnread(for cid: ChannelId, userId: UserId, from messageId: MessageId, lastReadMessageId: MessageId?, completion: ((Error?) -> Void)? = nil) {
        markUnreadCid = cid
        markUnreadUserId = userId
        markUnreadMessageId = messageId
        markUnreadLastReadMessageId = lastReadMessageId

        markUnreadResult.map {
            completion?($0.error)
        }
    }
}
