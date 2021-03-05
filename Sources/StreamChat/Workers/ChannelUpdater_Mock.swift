//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelUpdater
class ChannelUpdaterMock<ExtraData: ExtraDataTypes>: ChannelUpdater<ExtraData> {
    @Atomic var update_channelQuery: _ChannelQuery<ExtraData>?
    @Atomic var update_channelCreatedCallback: ((ChannelId) -> Void)?
    @Atomic var update_completion: ((Error?) -> Void)?

    @Atomic var updateChannel_payload: ChannelEditDetailPayload<ExtraData>?
    @Atomic var updateChannel_completion: ((Error?) -> Void)?

    @Atomic var muteChannel_cid: ChannelId?
    @Atomic var muteChannel_mute: Bool?
    @Atomic var muteChannel_completion: ((Error?) -> Void)?

    @Atomic var deleteChannel_cid: ChannelId?
    @Atomic var deleteChannel_completion: ((Error?) -> Void)?

    @Atomic var truncateChannel_cid: ChannelId?
    @Atomic var truncateChannel_completion: ((Error?) -> Void)?

    @Atomic var hideChannel_cid: ChannelId?
    @Atomic var hideChannel_clearHistory: Bool?
    @Atomic var hideChannel_completion: ((Error?) -> Void)?

    @Atomic var showChannel_cid: ChannelId?
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
    @Atomic var createNewMessage_attachments: [AttachmentEnvelope]?
    @Atomic var createNewMessage_attachmentSeeds: [ChatMessageAttachmentSeed]?
    @Atomic var createNewMessage_quotedMessageId: MessageId?
    @Atomic var createNewMessage_extraData: ExtraData.Message?
    @Atomic var createNewMessage_completion: ((Result<MessageId, Error>) -> Void)?
    
    @Atomic var markRead_cid: ChannelId?
    @Atomic var markRead_completion: ((Error?) -> Void)?
    
    @Atomic var enableSlowMode_cid: ChannelId?
    @Atomic var enableSlowMode_cooldownDuration: Int?
    @Atomic var enableSlowMode_completion: ((Error?) -> Void)?
    
    // Cleans up all recorded values
    func cleanUp() {
        update_channelQuery = nil
        update_channelCreatedCallback = nil
        update_completion = nil
        
        updateChannel_payload = nil
        updateChannel_completion = nil
        
        muteChannel_cid = nil
        muteChannel_mute = nil
        muteChannel_completion = nil
        
        deleteChannel_cid = nil
        deleteChannel_completion = nil

        truncateChannel_cid = nil
        truncateChannel_completion = nil
        
        hideChannel_cid = nil
        hideChannel_clearHistory = nil
        hideChannel_completion = nil
        
        showChannel_cid = nil
        showChannel_completion = nil
        
        addMembers_cid = nil
        addMembers_userIds = nil
        addMembers_completion = nil
        
        removeMembers_cid = nil
        removeMembers_userIds = nil
        removeMembers_completion = nil
        
        createNewMessage_cid = nil
        createNewMessage_text = nil
        createNewMessage_command = nil
        createNewMessage_arguments = nil
        createNewMessage_attachments = nil
        createNewMessage_attachmentSeeds = nil
        createNewMessage_extraData = nil
        createNewMessage_completion = nil
        
        markRead_cid = nil
        markRead_completion = nil
        
        enableSlowMode_cid = nil
        enableSlowMode_cooldownDuration = nil
        enableSlowMode_completion = nil
    }
    
    override func update(
        channelQuery: _ChannelQuery<ExtraData>,
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

    override func truncateChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        truncateChannel_cid = cid
        truncateChannel_completion = completion
    }

    override func hideChannel(cid: ChannelId, clearHistory: Bool, completion: ((Error?) -> Void)? = nil) {
        hideChannel_cid = cid
        hideChannel_clearHistory = clearHistory
        hideChannel_completion = completion
    }

    override func showChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        showChannel_cid = cid
        showChannel_completion = completion
    }
    
    override func createNewMessage(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        attachments: [AttachmentEnvelope],
        quotedMessageId: MessageId?,
        extraData: ExtraData.Message,
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        createNewMessage_cid = cid
        createNewMessage_text = text
        createNewMessage_command = command
        createNewMessage_arguments = arguments
        createNewMessage_attachments = attachments
        createNewMessage_quotedMessageId = quotedMessageId
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
    
    override func enableSlowMode(cid: ChannelId, cooldownDuration: Int, completion: ((Error?) -> Void)? = nil) {
        enableSlowMode_cid = cid
        enableSlowMode_cooldownDuration = cooldownDuration
        enableSlowMode_completion = completion
    }
}
