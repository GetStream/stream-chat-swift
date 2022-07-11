//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelUpdater
final class ChannelUpdater_Mock: ChannelUpdater {
    @Atomic var update_channelQuery: ChannelQuery?
    @Atomic var update_channelCreatedCallback: ((ChannelId) -> Void)?
    @Atomic var update_completion: ((Result<ChannelPayload, Error>) -> Void)?
    @Atomic var update_callCount = 0

    @Atomic var updateChannel_payload: ChannelEditDetailPayload?
    @Atomic var updateChannel_completion: ((Error?) -> Void)?

    @Atomic var muteChannel_cid: ChannelId?
    @Atomic var muteChannel_mute: Bool?
    @Atomic var muteChannel_completion: ((Error?) -> Void)?

    @Atomic var deleteChannel_cid: ChannelId?
    @Atomic var deleteChannel_completion: ((Error?) -> Void)?

    @Atomic var truncateChannel_cid: ChannelId?
    @Atomic var truncateChannel_completion: ((Error?) -> Void)?
    @Atomic var truncateChannel_skipPush: Bool?
    @Atomic var truncateChannel_hardDelete: Bool?
    @Atomic var truncateChannel_systemMessage: String?

    @Atomic var hideChannel_cid: ChannelId?
    @Atomic var hideChannel_clearHistory: Bool?
    @Atomic var hideChannel_completion: ((Error?) -> Void)?

    @Atomic var showChannel_cid: ChannelId?
    @Atomic var showChannel_completion: ((Error?) -> Void)?
    
    @Atomic var addMembers_cid: ChannelId?
    @Atomic var addMembers_userIds: Set<UserId>?
    @Atomic var addMembers_hideHistory: Bool?
    @Atomic var addMembers_completion: ((Error?) -> Void)?
    
    @Atomic var inviteMembers_cid: ChannelId?
    @Atomic var inviteMembers_userIds: Set<UserId>?
    @Atomic var inviteMembers_completion: ((Error?) -> Void)?
    
    @Atomic var acceptInvite_cid: ChannelId?
    @Atomic var acceptInvite_message: String?
    @Atomic var acceptInvite_completion: ((Error?) -> Void)?
    
    @Atomic var rejectInvite_cid: ChannelId?
    @Atomic var rejectInvite_completion: ((Error?) -> Void)?
    
    @Atomic var removeMembers_cid: ChannelId?
    @Atomic var removeMembers_userIds: Set<UserId>?
    @Atomic var removeMembers_completion: ((Error?) -> Void)?

    @Atomic var createNewMessage_cid: ChannelId?
    @Atomic var createNewMessage_text: String?
    @Atomic var createNewMessage_isSilent: Bool?
    @Atomic var createNewMessage_command: String?
    @Atomic var createNewMessage_arguments: String?
    @Atomic var createNewMessage_attachments: [AnyAttachmentPayload]?
    @Atomic var createNewMessage_mentionedUserIds: [UserId]?
    @Atomic var createNewMessage_quotedMessageId: MessageId?
    @Atomic var createNewMessage_pinning: MessagePinning?
    @Atomic var createNewMessage_extraData: [String: RawJSON]?
    @Atomic var createNewMessage_completion: ((Result<MessageId, Error>) -> Void)?
    
    @Atomic var markRead_cid: ChannelId?
    @Atomic var markRead_userId: UserId?
    @Atomic var markRead_completion: ((Error?) -> Void)?
    
    @Atomic var enableSlowMode_cid: ChannelId?
    @Atomic var enableSlowMode_cooldownDuration: Int?
    @Atomic var enableSlowMode_completion: ((Error?) -> Void)?
    
    @Atomic var startWatching_cid: ChannelId?
    @Atomic var startWatching_completion: ((Error?) -> Void)?
    
    @Atomic var stopWatching_cid: ChannelId?
    @Atomic var stopWatching_completion: ((Error?) -> Void)?
    
    @Atomic var channelWatchers_query: ChannelWatcherListQuery?
    @Atomic var channelWatchers_completion: ((Error?) -> Void)?
    
    @Atomic var freezeChannel_freeze: Bool?
    @Atomic var freezeChannel_cid: ChannelId?
    @Atomic var freezeChannel_completion: ((Error?) -> Void)?
    
    @Atomic var uploadFile_type: AttachmentType?
    @Atomic var uploadFile_localFileURL: URL?
    @Atomic var uploadFile_cid: ChannelId?
    @Atomic var uploadFile_progress: ((Double) -> Void)?
    @Atomic var uploadFile_completion: ((Result<URL, Error>) -> Void)?
    
    @Atomic var loadPinnedMessages_cid: ChannelId?
    @Atomic var loadPinnedMessages_query: PinnedMessagesQuery?
    @Atomic var loadPinnedMessages_completion: ((Result<[ChatMessage], Error>) -> Void)?
    
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
        
        inviteMembers_cid = nil
        inviteMembers_userIds = nil
        inviteMembers_completion = nil
        
        acceptInvite_cid = nil
        acceptInvite_message = nil
        acceptInvite_completion = nil
        
        rejectInvite_cid = nil
        rejectInvite_completion = nil
        
        removeMembers_cid = nil
        removeMembers_userIds = nil
        removeMembers_completion = nil
        
        createNewMessage_cid = nil
        createNewMessage_text = nil
        createNewMessage_isSilent = nil
        createNewMessage_command = nil
        createNewMessage_arguments = nil
        createNewMessage_attachments = nil
        createNewMessage_mentionedUserIds = nil
        createNewMessage_extraData = nil
        createNewMessage_completion = nil
        
        markRead_cid = nil
        markRead_completion = nil
        
        enableSlowMode_cid = nil
        enableSlowMode_cooldownDuration = nil
        enableSlowMode_completion = nil
        
        startWatching_cid = nil
        startWatching_completion = nil
        
        stopWatching_cid = nil
        stopWatching_completion = nil
        
        channelWatchers_query = nil
        channelWatchers_completion = nil
        
        freezeChannel_freeze = nil
        freezeChannel_cid = nil
        freezeChannel_completion = nil
        
        uploadFile_type = nil
        uploadFile_localFileURL = nil
        uploadFile_cid = nil
        uploadFile_progress = nil
        uploadFile_completion = nil
        
        loadPinnedMessages_cid = nil
        loadPinnedMessages_query = nil
        loadPinnedMessages_completion = nil
    }
    
    override func update(
        channelQuery: ChannelQuery,
        isInRecoveryMode: Bool,
        channelCreatedCallback: ((ChannelId) -> Void)?,
        completion: ((Result<ChannelPayload, Error>) -> Void)?
    ) {
        update_channelQuery = channelQuery
        update_channelCreatedCallback = channelCreatedCallback
        update_completion = completion
        update_callCount += 1
    }

    override func updateChannel(channelPayload: ChannelEditDetailPayload, completion: ((Error?) -> Void)? = nil) {
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

    override func truncateChannel(
        cid: ChannelId,
        skipPush: Bool = false,
        hardDelete: Bool = true,
        systemMessage: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        truncateChannel_cid = cid
        truncateChannel_skipPush = skipPush
        truncateChannel_hardDelete = hardDelete
        truncateChannel_systemMessage = systemMessage
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
        pinning: MessagePinning?,
        isSilent: Bool,
        command: String?,
        arguments: String?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        quotedMessageId: MessageId?,
        extraData: [String: RawJSON] = [:],
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        createNewMessage_cid = cid
        createNewMessage_text = text
        createNewMessage_isSilent = isSilent
        createNewMessage_command = command
        createNewMessage_arguments = arguments
        createNewMessage_attachments = attachments
        createNewMessage_mentionedUserIds = mentionedUserIds
        createNewMessage_quotedMessageId = quotedMessageId
        createNewMessage_pinning = pinning
        createNewMessage_extraData = extraData
        createNewMessage_completion = completion
    }
    
    override func addMembers(cid: ChannelId, userIds: Set<UserId>, hideHistory: Bool, completion: ((Error?) -> Void)? = nil) {
        addMembers_cid = cid
        addMembers_userIds = userIds
        addMembers_hideHistory = hideHistory
        addMembers_completion = completion
    }
    
    override func inviteMembers(
        cid: ChannelId,
        userIds: Set<UserId>,
        completion: ((Error?) -> Void)? = nil
    ) {
        inviteMembers_cid = cid
        inviteMembers_userIds = userIds
        inviteMembers_completion = completion
    }
    
    override func acceptInvite(
        cid: ChannelId,
        message: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        acceptInvite_cid = cid
        acceptInvite_message = message
        acceptInvite_completion = completion
    }
    
    override func rejectInvite(
        cid: ChannelId,
        completion: ((Error?) -> Void)? = nil
    ) {
        rejectInvite_cid = cid
        rejectInvite_completion = completion
    }
    
    override func removeMembers(cid: ChannelId, userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        removeMembers_cid = cid
        removeMembers_userIds = userIds
        removeMembers_completion = completion
    }
    
    override func markRead(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        markRead_cid = cid
        markRead_userId = userId
        markRead_completion = completion
    }
    
    override func enableSlowMode(cid: ChannelId, cooldownDuration: Int, completion: ((Error?) -> Void)? = nil) {
        enableSlowMode_cid = cid
        enableSlowMode_cooldownDuration = cooldownDuration
        enableSlowMode_completion = completion
    }
    
    override func startWatching(cid: ChannelId, isInRecoveryMode: Bool, completion: ((Error?) -> Void)? = nil) {
        startWatching_cid = cid
        startWatching_completion = completion
    }
    
    override func stopWatching(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        stopWatching_cid = cid
        stopWatching_completion = completion
    }
    
    override func channelWatchers(query: ChannelWatcherListQuery, completion: ((Error?) -> Void)? = nil) {
        channelWatchers_query = query
        channelWatchers_completion = completion
    }
    
    override func freezeChannel(_ freeze: Bool, cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        freezeChannel_freeze = freeze
        freezeChannel_cid = cid
        freezeChannel_completion = completion
    }
    
    override func uploadFile(
        type: AttachmentType,
        localFileURL: URL,
        cid: ChannelId,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping ((Result<URL, Error>) -> Void)
    ) {
        uploadFile_type = type
        uploadFile_localFileURL = localFileURL
        uploadFile_cid = cid
        uploadFile_progress = progress
        uploadFile_completion = completion
    }
    
    override func loadPinnedMessages(
        in cid: ChannelId,
        query: PinnedMessagesQuery,
        completion: @escaping (Result<[ChatMessage], Error>) -> Void
    ) {
        loadPinnedMessages_cid = cid
        loadPinnedMessages_query = query
        loadPinnedMessages_completion = completion
    }
}
