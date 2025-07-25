//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelUpdater
final class ChannelUpdater_Mock: ChannelUpdater {
    @Atomic var update_channelQuery: ChannelQuery?
    @Atomic var update_onChannelCreated: ((ChannelId) -> Void)?
    @Atomic var update_completion: ((Result<ChannelPayload, Error>) -> Void)?
    @Atomic var update_callCount = 0

    @Atomic var updateChannel_payload: ChannelEditDetailPayload?
    @Atomic var updateChannel_completion: ((Error?) -> Void)?

    @Atomic var partialChannelUpdate_updates: ChannelEditDetailPayload?
    @Atomic var partialChannelUpdate_unsetProperties: [String]?
    @Atomic var partialChannelUpdate_completion: ((Error?) -> Void)?

    @Atomic var muteChannel_cid: ChannelId?
    @Atomic var muteChannel_expiration: Int?
    @Atomic var muteChannel_completion: ((Error?) -> Void)?
    @Atomic var muteChannel_completion_result: Result<Void, Error>?

    @Atomic var unmuteChannel_cid: ChannelId?
    @Atomic var unmuteChannel_completion: ((Error?) -> Void)?
    @Atomic var unmuteChannel_completion_result: Result<Void, Error>?

    @Atomic var deleteChannel_cid: ChannelId?
    @Atomic var deleteChannel_completion: ((Error?) -> Void)?
    @Atomic var deleteChannel_completion_result: Result<Void, Error>?

    @Atomic var truncateChannel_cid: ChannelId?
    @Atomic var truncateChannel_skipPush: Bool?
    @Atomic var truncateChannel_hardDelete: Bool?
    @Atomic var truncateChannel_systemMessage: String?
    @Atomic var truncateChannel_completion: ((Error?) -> Void)?
    @Atomic var truncateChannel_completion_result: Result<Void, Error>?

    @Atomic var hideChannel_cid: ChannelId?
    @Atomic var hideChannel_clearHistory: Bool?
    @Atomic var hideChannel_completion: ((Error?) -> Void)?
    @Atomic var hideChannel_completion_result: Result<Void, Error>?

    @Atomic var showChannel_cid: ChannelId?
    @Atomic var showChannel_completion: ((Error?) -> Void)?
    @Atomic var showChannel_completion_result: Result<Void, Error>?
    
    @Atomic var addMembers_currentUserId: UserId?
    @Atomic var addMembers_cid: ChannelId?
    @Atomic var addMembers_userIds: Set<UserId>?
    @Atomic var addMembers_memberInfos: [MemberInfo]?
    @Atomic var addMembers_message: String?
    @Atomic var addMembers_hideHistory: Bool?
    @Atomic var addMembers_completion: ((Error?) -> Void)?
    @Atomic var addMembers_completion_result: Result<Void, Error>?

    @Atomic var inviteMembers_cid: ChannelId?
    @Atomic var inviteMembers_userIds: Set<UserId>?
    @Atomic var inviteMembers_completion: ((Error?) -> Void)?
    @Atomic var inviteMembers_completion_result: Result<Void, Error>?

    @Atomic var acceptInvite_cid: ChannelId?
    @Atomic var acceptInvite_message: String?
    @Atomic var acceptInvite_completion: ((Error?) -> Void)?
    @Atomic var acceptInvite_completion_result: Result<Void, Error>?

    @Atomic var rejectInvite_cid: ChannelId?
    @Atomic var rejectInvite_completion: ((Error?) -> Void)?
    @Atomic var rejectInvite_completion_result: Result<Void, Error>?
    
    @Atomic var removeMembers_currentUserId: UserId?
    @Atomic var removeMembers_cid: ChannelId?
    @Atomic var removeMembers_userIds: Set<UserId>?
    @Atomic var removeMembers_message: String?
    @Atomic var removeMembers_completion: ((Error?) -> Void)?
    @Atomic var removeMembers_completion_result: Result<Void, Error>?

    @Atomic var createNewMessage_cid: ChannelId?
    @Atomic var createNewMessage_text: String?
    @Atomic var createNewMessage_isSilent: Bool?
    @Atomic var createNewMessage_isSystem: Bool?
    @Atomic var createNewMessage_skipPush: Bool?
    @Atomic var createNewMessage_skipEnrichUrl: Bool?
    @Atomic var createNewMessage_command: String?
    @Atomic var createNewMessage_arguments: String?
    @Atomic var createNewMessage_attachments: [AnyAttachmentPayload]?
    @Atomic var createNewMessage_mentionedUserIds: [UserId]?
    @Atomic var createNewMessage_quotedMessageId: MessageId?
    @Atomic var createNewMessage_pinning: MessagePinning?
    @Atomic var createNewMessage_location: NewLocationInfo?
    @Atomic var createNewMessage_extraData: [String: RawJSON]?
    @Atomic var createNewMessage_completion: ((Result<ChatMessage, Error>) -> Void)?
    @Atomic var createNewMessage_completion_result: Result<ChatMessage, Error>?

    @Atomic var markRead_cid: ChannelId?
    @Atomic var markRead_userId: UserId?
    @Atomic var markRead_completion: ((Error?) -> Void)?
    @Atomic var markRead_completion_result: Result<Void, Error>?

    @Atomic var markUnread_cid: ChannelId?
    @Atomic var markUnread_userId: UserId?
    @Atomic var markUnread_messageId: MessageId?
    @Atomic var markUnread_lastReadMessageId: MessageId?
    @Atomic var markUnread_completion: ((Result<ChatChannel, Error>) -> Void)?
    @Atomic var markUnread_completion_result: Result<ChatChannel, Error>?

    @Atomic var enableSlowMode_cid: ChannelId?
    @Atomic var enableSlowMode_cooldownDuration: Int?
    @Atomic var enableSlowMode_completion: ((Error?) -> Void)?
    @Atomic var enableSlowMode_completion_result: Result<Void, Error>?

    @Atomic var startWatching_cid: ChannelId?
    @Atomic var startWatching_completion: ((Error?) -> Void)?
    @Atomic var startWatching_completion_result: Result<Void, Error>?

    @Atomic var stopWatching_cid: ChannelId?
    @Atomic var stopWatching_completion: ((Error?) -> Void)?
    @Atomic var stopWatching_completion_result: Result<Void, Error>?

    @Atomic var channelWatchers_query: ChannelWatcherListQuery?
    @Atomic var channelWatchers_completion: ((Result<ChannelPayload, any Error>) -> Void)?

    @Atomic var freezeChannel_freeze: Bool?
    @Atomic var freezeChannel_cid: ChannelId?
    @Atomic var freezeChannel_completion: ((Error?) -> Void)?
    @Atomic var freezeChannel_completion_result: Result<Void, Error>?

    @Atomic var uploadFile_type: AttachmentType?
    @Atomic var uploadFile_localFileURL: URL?
    @Atomic var uploadFile_cid: ChannelId?
    @Atomic var uploadFile_progress: ((Double) -> Void)?
    @Atomic var uploadFile_completion: ((Result<UploadedAttachment, Error>) -> Void)?

    @Atomic var loadPinnedMessages_cid: ChannelId?
    @Atomic var loadPinnedMessages_query: PinnedMessagesQuery?
    @Atomic var loadPinnedMessages_completion: ((Result<[ChatMessage], Error>) -> Void)?
    @Atomic var loadPinnedMessages_completion_result: Result<[ChatMessage], Error>?

    @Atomic var loadMembersWithReads_cid: ChannelId?
    @Atomic var loadMembersWithReads_pagination: Pagination?
    @Atomic var loadMembersWithReads_sorting: [Sorting<ChannelMemberListSortingKey>]?
    @Atomic var loadMembersWithReads_completion: ((Result<[ChatChannelMember], Error>) -> Void)?
    @Atomic var loadMembersWithReads_completion_result: Result<[ChatChannelMember], Error>?
    
    @Atomic var createCall_cid: ChannelId?

    @Atomic var enrichUrl_url: URL?
    @Atomic var enrichUrl_callCount = 0
    @Atomic var enrichUrl_completion: ((Result<LinkAttachmentPayload, Error>) -> Void)?
    @Atomic var enrichUrl_completion_result: Result<LinkAttachmentPayload, Error>?

    // Cleans up all recorded values
    func cleanUp() {
        update_channelQuery = nil
        update_onChannelCreated = nil
        update_completion = nil

        updateChannel_payload = nil
        updateChannel_completion = nil

        muteChannel_cid = nil
        muteChannel_expiration = nil
        muteChannel_completion = nil
        muteChannel_completion_result = nil

        unmuteChannel_cid = nil
        unmuteChannel_completion = nil
        unmuteChannel_completion_result = nil

        deleteChannel_cid = nil
        deleteChannel_completion = nil
        deleteChannel_completion_result = nil

        truncateChannel_cid = nil
        truncateChannel_skipPush = nil
        truncateChannel_hardDelete = nil
        truncateChannel_systemMessage = nil
        truncateChannel_completion = nil
        truncateChannel_completion_result = nil

        hideChannel_cid = nil
        hideChannel_clearHistory = nil
        hideChannel_completion = nil
        hideChannel_completion_result = nil

        showChannel_cid = nil
        showChannel_completion = nil
        showChannel_completion_result = nil

        addMembers_currentUserId = nil
        addMembers_cid = nil
        addMembers_message = nil
        addMembers_userIds = nil
        addMembers_hideHistory = nil
        addMembers_completion = nil
        addMembers_completion_result = nil

        inviteMembers_cid = nil
        inviteMembers_userIds = nil
        inviteMembers_completion = nil
        inviteMembers_completion_result = nil

        acceptInvite_cid = nil
        acceptInvite_message = nil
        acceptInvite_completion = nil
        acceptInvite_completion_result = nil

        rejectInvite_cid = nil
        rejectInvite_completion = nil
        rejectInvite_completion_result = nil

        removeMembers_currentUserId = nil
        removeMembers_cid = nil
        removeMembers_message = nil
        removeMembers_userIds = nil
        removeMembers_completion = nil
        removeMembers_completion_result = nil

        createNewMessage_cid = nil
        createNewMessage_text = nil
        createNewMessage_isSilent = nil
        createNewMessage_skipPush = nil
        createNewMessage_skipEnrichUrl = nil
        createNewMessage_command = nil
        createNewMessage_arguments = nil
        createNewMessage_attachments = nil
        createNewMessage_mentionedUserIds = nil
        createNewMessage_extraData = nil
        createNewMessage_completion = nil
        createNewMessage_completion_result = nil

        markRead_cid = nil
        markRead_userId = nil
        markRead_completion = nil
        markRead_completion_result = nil
        
        markUnread_cid = nil
        markUnread_userId = nil
        markUnread_messageId = nil
        markUnread_lastReadMessageId = nil
        markUnread_completion = nil
        markUnread_completion_result = nil

        enableSlowMode_cid = nil
        enableSlowMode_cooldownDuration = nil
        enableSlowMode_completion = nil
        enableSlowMode_completion_result = nil

        startWatching_cid = nil
        startWatching_completion = nil
        startWatching_completion_result = nil

        stopWatching_cid = nil
        stopWatching_completion = nil
        stopWatching_completion_result = nil

        channelWatchers_query = nil
        channelWatchers_completion = nil

        freezeChannel_freeze = nil
        freezeChannel_cid = nil
        freezeChannel_completion = nil
        freezeChannel_completion_result = nil

        uploadFile_type = nil
        uploadFile_localFileURL = nil
        uploadFile_cid = nil
        uploadFile_progress = nil
        uploadFile_completion = nil

        loadPinnedMessages_cid = nil
        loadPinnedMessages_query = nil
        loadPinnedMessages_completion = nil
        loadPinnedMessages_completion_result = nil
        
        loadMembersWithReads_cid = nil
        loadMembersWithReads_pagination = nil
        loadMembersWithReads_sorting = nil
        loadMembersWithReads_completion = nil
        loadMembersWithReads_completion_result = nil

        createCall_cid = nil

        enrichUrl_url = nil
        enrichUrl_completion = nil
        enrichUrl_completion_result = nil
    }

    var mockPaginationState: MessagesPaginationState = .initial
    override var paginationState: MessagesPaginationState {
        mockPaginationState
    }
    override func update(
        channelQuery: ChannelQuery,
        isInRecoveryMode: Bool,
        onChannelCreated: ((ChannelId) -> Void)? = nil,
        actions: ChannelUpdateActions? = nil,
        completion: ((Result<ChannelPayload, Error>) -> Void)? = nil
    ) {
        update_channelQuery = channelQuery
        update_onChannelCreated = onChannelCreated
        update_completion = completion
        update_callCount += 1
    }

    override func updateChannel(channelPayload: ChannelEditDetailPayload, completion: ((Error?) -> Void)? = nil) {
        updateChannel_payload = channelPayload
        updateChannel_completion = completion
    }

    override func partialChannelUpdate(updates: ChannelEditDetailPayload, unsetProperties: [String], completion: ((Error?) -> Void)? = nil) {
        partialChannelUpdate_updates = updates
        partialChannelUpdate_unsetProperties = unsetProperties
        partialChannelUpdate_completion = completion
    }

    override func muteChannel(cid: ChannelId, expiration: Int? = nil, completion: ((Error?) -> Void)? = nil) {
        muteChannel_cid = cid
        muteChannel_expiration = expiration
        muteChannel_completion = completion
        muteChannel_completion_result?.invoke(with: completion)
    }

    override func unmuteChannel(cid: ChannelId, completion: (((any Error)?) -> Void)? = nil) {
        unmuteChannel_cid = cid
        unmuteChannel_completion = completion
        unmuteChannel_completion_result?.invoke(with: completion)
    }

    override func deleteChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        deleteChannel_cid = cid
        deleteChannel_completion = completion
        deleteChannel_completion_result?.invoke(with: completion)
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
        truncateChannel_completion_result?.invoke(with: completion)
    }

    override func hideChannel(cid: ChannelId, clearHistory: Bool, completion: ((Error?) -> Void)? = nil) {
        hideChannel_cid = cid
        hideChannel_clearHistory = clearHistory
        hideChannel_completion = completion
        hideChannel_completion_result?.invoke(with: completion)
    }

    override func showChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        showChannel_cid = cid
        showChannel_completion = completion
        showChannel_completion_result?.invoke(with: completion)
    }

    override func createNewMessage(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning?,
        isSilent: Bool,
        isSystem: Bool,
        command: String?,
        arguments: String?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        quotedMessageId: MessageId?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        restrictedVisibility: [UserId] = [],
        poll: PollPayload?,
        location: NewLocationInfo? = nil,
        extraData: [String: RawJSON] = [:],
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        createNewMessage_cid = cid
        createNewMessage_text = text
        createNewMessage_isSilent = isSilent
        createNewMessage_isSystem = isSystem
        createNewMessage_skipPush = skipPush
        createNewMessage_skipEnrichUrl = skipEnrichUrl
        createNewMessage_command = command
        createNewMessage_arguments = arguments
        createNewMessage_attachments = attachments
        createNewMessage_mentionedUserIds = mentionedUserIds
        createNewMessage_quotedMessageId = quotedMessageId
        createNewMessage_pinning = pinning
        createNewMessage_extraData = extraData
        createNewMessage_location = location
        createNewMessage_completion = completion
        createNewMessage_completion_result?.invoke(with: completion)
    }

    override func addMembers(
        currentUserId: UserId?,
        cid: ChannelId,
        members: [MemberInfo],
        message: String?,
        hideHistory: Bool,
        completion: ((Error?) -> Void)? = nil
    ) {
        addMembers_currentUserId = currentUserId
        addMembers_cid = cid
        addMembers_userIds = Set(members.map(\.userId))
        addMembers_memberInfos = members
        addMembers_message = message
        addMembers_hideHistory = hideHistory
        addMembers_completion = completion
        addMembers_completion_result?.invoke(with: completion)
    }

    func addMembers(
        currentUserId: UserId?,
        cid: ChannelId,
        userIds: Set<UserId>,
        message: String?,
        hideHistory: Bool,
        completion: ((Error?) -> Void)? = nil
    ) {
        self.addMembers(
            currentUserId: currentUserId,
            cid: cid,
            members: userIds.map { MemberInfo(userId: $0, extraData: nil) },
            message: message,
            hideHistory: hideHistory,
            completion: completion
        )
    }

    override func inviteMembers(
        cid: ChannelId,
        userIds: Set<UserId>,
        completion: ((Error?) -> Void)? = nil
    ) {
        inviteMembers_cid = cid
        inviteMembers_userIds = userIds
        inviteMembers_completion = completion
        inviteMembers_completion_result?.invoke(with: completion)
    }

    override func acceptInvite(
        cid: ChannelId,
        message: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        acceptInvite_cid = cid
        acceptInvite_message = message
        acceptInvite_completion = completion
        acceptInvite_completion_result?.invoke(with: completion)
    }

    override func rejectInvite(
        cid: ChannelId,
        completion: ((Error?) -> Void)? = nil
    ) {
        rejectInvite_cid = cid
        rejectInvite_completion = completion
        rejectInvite_completion_result?.invoke(with: completion)
    }

    override func removeMembers(
        currentUserId: UserId?,
        cid: ChannelId,
        userIds: Set<UserId>,
        message: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        removeMembers_currentUserId = currentUserId
        removeMembers_cid = cid
        removeMembers_userIds = userIds
        removeMembers_message = message
        removeMembers_completion = completion
        removeMembers_completion_result?.invoke(with: completion)
    }

    override func markRead(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        markRead_cid = cid
        markRead_userId = userId
        markRead_completion = completion
        markRead_completion_result?.invoke(with: completion)
    }

    override func markUnread(cid: ChannelId, userId: UserId, from messageId: MessageId, lastReadMessageId: MessageId?, completion: ((Result<ChatChannel, Error>) -> Void)? = nil) {
        markUnread_cid = cid
        markUnread_userId = userId
        markUnread_messageId = messageId
        markUnread_lastReadMessageId = lastReadMessageId
        markUnread_completion = completion
        markUnread_completion_result?.invoke(with: completion)
    }

    override func enableSlowMode(cid: ChannelId, cooldownDuration: Int, completion: ((Error?) -> Void)? = nil) {
        enableSlowMode_cid = cid
        enableSlowMode_cooldownDuration = cooldownDuration
        enableSlowMode_completion = completion
        enableSlowMode_completion_result?.invoke(with: completion)
    }

    override func startWatching(cid: ChannelId, isInRecoveryMode: Bool, completion: ((Error?) -> Void)? = nil) {
        startWatching_cid = cid
        startWatching_completion = completion
        startWatching_completion_result?.invoke(with: completion)
    }

    override func stopWatching(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        stopWatching_cid = cid
        stopWatching_completion = completion
        stopWatching_completion_result?.invoke(with: completion)
    }

    override func channelWatchers(query: ChannelWatcherListQuery, completion: ((Result<ChannelPayload, any Error>) -> Void)? = nil) {
        channelWatchers_query = query
        channelWatchers_completion = completion
    }

    override func freezeChannel(_ freeze: Bool, cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        freezeChannel_freeze = freeze
        freezeChannel_cid = cid
        freezeChannel_completion = completion
        freezeChannel_completion_result?.invoke(with: completion)
    }

    override func uploadFile(
        type: AttachmentType,
        localFileURL: URL,
        cid: ChannelId,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping ((Result<UploadedAttachment, Error>) -> Void)
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
        loadPinnedMessages_completion_result?.invoke(with: completion)
    }
    
    override func loadMembersWithReads(in cid: ChannelId, membersPagination: Pagination, memberListSorting: [Sorting<ChannelMemberListSortingKey>], completion: @escaping (Result<([ChatChannelMember]), any Error>) -> Void) {
        loadMembersWithReads_cid = cid
        loadMembersWithReads_pagination = membersPagination
        loadMembersWithReads_sorting = memberListSorting
        loadMembersWithReads_completion = completion
        loadMembersWithReads_completion_result?.invoke(with: completion)
    }

    override func enrichUrl(_ url: URL, completion: @escaping (Result<LinkAttachmentPayload, Error>) -> Void) {
        enrichUrl_callCount += 1
        enrichUrl_url = url
        enrichUrl_completion = completion
        enrichUrl_completion_result?.invoke(with: completion)
    }
}
