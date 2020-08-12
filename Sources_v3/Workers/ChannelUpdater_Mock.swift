//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

/// Mock implementation of ChannelUpdater
class ChannelUpdaterMock<ExtraData: ExtraDataTypes>: ChannelUpdater<ExtraData> {
    var update_channelQuery: ChannelQuery<ExtraData>?
    var update_completion: ((Error?) -> Void)?

    var muteChannel_cid: ChannelId?
    var muteChannel_mute: Bool?
    var muteChannel_completion: ((Error?) -> Void)?

    var deleteChannel_cid: ChannelId?
    var deleteChannel_completion: ((Error?) -> Void)?

    var hideChannel_cid: ChannelId?
    var hideChannel_userId: UserId?
    var hideChannel_clearHistory: Bool?
    var hideChannel_completion: ((Error?) -> Void)?

    var showChannel_cid: ChannelId?
    var showChannel_userId: UserId?
    var showChannel_completion: ((Error?) -> Void)?

    override func update(channelQuery: ChannelQuery<ExtraData>, completion: ((Error?) -> Void)? = nil) {
        update_channelQuery = channelQuery
        update_completion = completion
    }

    override func muteChannel(cid: ChannelId, mute: Bool, completion: ((Error?) -> Void)? = nil) {
        muteChannel_cid = cid
        muteChannel_mute = mute
        muteChannel_completion = completion
    }

    override func deleteChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        deleteChannel_cid = cid
        deleteChannel_completion = completion
    }

    override func hideChannel(cid: ChannelId, userId: UserId, clearHistory: Bool, completion: ((Error?) -> Void)? = nil) {
        hideChannel_cid = cid
        hideChannel_userId = userId
        hideChannel_clearHistory = clearHistory
        hideChannel_completion = completion
    }

    override func showChannel(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        showChannel_cid = cid
        showChannel_userId = userId
        showChannel_completion = completion
    }
}
