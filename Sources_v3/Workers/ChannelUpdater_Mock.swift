//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

/// Mock implementation of ChannelUpdater
class ChannelUpdaterMock<ExtraData: ExtraDataTypes>: ChannelUpdater<ExtraData> {
    @Atomic var update_channelQuery: ChannelQuery<ExtraData>?
    @Atomic var update_channelCreatedCallback: ((ChannelId) -> Void)?
    @Atomic var update_completion: ((Error?) -> Void)?

    @Atomic var updateChannel_payload: ChannelEditDetailPayload<ExtraData>?
    @Atomic var updateChannel_completion: ((Error?) -> Void)?

    @Atomic var muteChannel_cid: ChannelId?
    @Atomic var muteChannel_mute: Bool?
    @Atomic var muteChannel_completion: ((Error?) -> Void)?

    @Atomic var deleteChannel_cid: ChannelId?
    @Atomic var deleteChannel_completion: ((Error?) -> Void)?

    @Atomic var hideChannel_cid: ChannelId?
    @Atomic var hideChannel_userId: UserId?
    @Atomic var hideChannel_clearHistory: Bool?
    @Atomic var hideChannel_completion: ((Error?) -> Void)?

    @Atomic var showChannel_cid: ChannelId?
    @Atomic var showChannel_userId: UserId?
    @Atomic var showChannel_completion: ((Error?) -> Void)?
    
    @Atomic var addMembers_cid: ChannelId?
    @Atomic var addMembers_userIds: Set<UserId>?
    @Atomic var addMembers_completion: ((Error?) -> Void)?
    
    @Atomic var removeMembers_cid: ChannelId?
    @Atomic var removeMembers_userIds: Set<UserId>?
    @Atomic var removeMembers_completion: ((Error?) -> Void)?

    @Atomic var createNewMessage_cid: ChannelId?
    @Atomic var createNewMessage_text: String?
    @Atomic var createNewMessage_command: String?
    @Atomic var createNewMessage_arguments: String?
    @Atomic var createNewMessage_parentMessageId: MessageId?
    @Atomic var createNewMessage_showReplyInChannel: Bool?
    @Atomic var createNewMessage_extraData: ExtraData.Message?
    @Atomic var createNewMessage_completion: ((Result<MessageId, Error>) -> Void)?
    
    @Atomic var markRead_cid: ChannelId?
    @Atomic var markRead_completion: ((Error?) -> Void)?
    
    override func update(
        channelQuery: ChannelQuery<ExtraData>,
        channelCreatedCallback: ((ChannelId) -> Void)?,
        completion: ((Error?) -> Void)?
    ) {
        update_channelQuery = channelQuery
        update_channelCreatedCallback = channelCreatedCallback
        update_completion = completion
    }

    override func updateChannel(channelPayload: ChannelEditDetailPayload<ExtraData>, completion: ((Error?) -> Void)? = nil) {
        updateChannel_payload = channelPayload
        updateChannel_completion = completion
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
    
    override func createNewMessage(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        showReplyInChannel: Bool,
        extraData: ExtraData.Message,
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        createNewMessage_cid = cid
        createNewMessage_text = text
        createNewMessage_command = command
        createNewMessage_arguments = arguments
        createNewMessage_parentMessageId = parentMessageId
        createNewMessage_showReplyInChannel = showReplyInChannel
        createNewMessage_extraData = extraData
        createNewMessage_completion = completion
    }
    
    override func addMembers(cid: ChannelId, userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        addMembers_cid = cid
        addMembers_userIds = userIds
        addMembers_completion = completion
    }
    
    override func removeMembers(cid: ChannelId, userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        removeMembers_cid = cid
        removeMembers_userIds = userIds
        removeMembers_completion = completion
    }
    
    override func markRead(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        markRead_cid = cid
        markRead_completion = completion
    }
}
