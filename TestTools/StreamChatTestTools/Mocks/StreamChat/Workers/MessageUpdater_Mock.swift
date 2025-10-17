//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of MessageUpdater
final class MessageUpdater_Mock: MessageUpdater {
    @Atomic var getMessage_cid: ChannelId?
    @Atomic var getMessage_messageId: MessageId?
    @Atomic var getMessage_completion: ((Result<ChatMessage, Error>) -> Void)?

    @Atomic var deleteMessage_messageId: MessageId?
    @Atomic var deleteMessage_completion: ((Error?) -> Void)?
    @Atomic var deleteMessage_completion_result: Result<Void, Error>?
    @Atomic var deleteMessage_hard: Bool?
    @Atomic var deleteMessage_deleteForMe: Bool?

    @Atomic var downloadAttachment_attachmentId: AttachmentId?
    @Atomic var downloadAttachment_completion_result: Result<AnyChatMessageAttachment, Error>?
    
    @Atomic var deleteLocalAttachmentDownload_attachmentId: AttachmentId?
    @Atomic var deleteLocalAttachmentDownload_completion_result: Result<Void, Error>?

    @Atomic var editMessage_messageId: MessageId?
    @Atomic var editMessage_text: String?
    @Atomic var editMessage_skipEnrichUrl: Bool?
    @Atomic var editMessage_skipPush: Bool?
    @Atomic var editMessage_restrictedVisibility: [UserId]?
    @Atomic var editMessage_attachments: [AnyAttachmentPayload]?
    @Atomic var editMessage_completion: ((Result<ChatMessage, Error>) -> Void)?
    @Atomic var editMessage_extraData: [String: RawJSON]?

    @Atomic var updateLiveLocation_messageId: MessageId?
    @Atomic var updateLiveLocation_locationInfo: LocationInfo?
    @Atomic var updateLiveLocation_completion: ((Result<SharedLocation, Error>) -> Void)?

    @Atomic var stopLiveLocationSharing_messageId: MessageId?
    @Atomic var stopLiveLocationSharing_completion: ((Result<SharedLocation, Error>) -> Void)?

    @Atomic var createNewReply_cid: ChannelId?
    @Atomic var createNewReply_text: String?
    @Atomic var createNewReply_command: String?
    @Atomic var createNewReply_arguments: String?
    @Atomic var createNewReply_parentMessageId: MessageId?
    @Atomic var createNewReply_attachments: [AnyAttachmentPayload]?
    @Atomic var createNewReply_mentionedUserIds: [UserId]?
    @Atomic var createNewReply_showReplyInChannel: Bool?
    @Atomic var createNewReply_isSilent: Bool?
    @Atomic var createNewReply_skipPush: Bool?
    @Atomic var createNewReply_skipEnrichUrl: Bool?
    @Atomic var createNewReply_quotedMessageId: MessageId?
    @Atomic var createNewReply_pinning: MessagePinning?
    @Atomic var createNewReply_extraData: [String: RawJSON]?
    @Atomic var createNewReply_completion: ((Result<ChatMessage, Error>) -> Void)?

    @Atomic var loadReplies_cid: ChannelId?
    @Atomic var loadReplies_callCount = 0
    @Atomic var loadReplies_messageId: MessageId?
    @Atomic var loadReplies_pagination: MessagesPagination?
    @Atomic var loadReplies_paginationStateHandler: MessagesPaginationStateHandling?
    @Atomic var loadReplies_completion: ((Result<MessageRepliesPayload, Error>) -> Void)?

    @Atomic var loadReactions_cid: ChannelId?
    @Atomic var loadReactions_messageId: MessageId?
    @Atomic var loadReactions_pagination: Pagination?
    @Atomic var loadReactions_completion: ((Result<[ChatMessageReaction], Error>) -> Void)?
    @Atomic var loadReactions_result: Result<[ChatMessageReaction], Error>?

    @Atomic var flagMessage_flag: Bool?
    @Atomic var flagMessage_messageId: MessageId?
    @Atomic var flagMessage_cid: ChannelId?
    @Atomic var flagMessage_reason: String?
    @Atomic var flagMessage_extraData: [String: RawJSON]?
    @Atomic var flagMessage_completion: ((Error?) -> Void)?
    @Atomic var flagMessage_completion_result: Result<Void, Error>?

    @Atomic var addReaction_type: MessageReactionType?
    @Atomic var addReaction_score: Int?
    @Atomic var addReaction_enforceUnique: Bool?
    @Atomic var addReaction_skipPush: Bool?
    @Atomic var addReaction_pushEmojiCode: String?
    @Atomic var addReaction_extraData: [String: RawJSON]?
    @Atomic var addReaction_messageId: MessageId?
    @Atomic var addReaction_completion: ((Error?) -> Void)?
    @Atomic var addReaction_completion_result: Result<Void, Error>?

    @Atomic var deleteReaction_type: MessageReactionType?
    @Atomic var deleteReaction_messageId: MessageId?
    @Atomic var deleteReaction_completion: ((Error?) -> Void)?
    @Atomic var deleteReaction_completion_result: Result<Void, Error>?

    @Atomic var pinMessage_messageId: MessageId?
    @Atomic var pinMessage_pinning: MessagePinning?
    @Atomic var pinMessage_completion: ((Result<ChatMessage, Error>) -> Void)?
    @Atomic var pinMessage_completion_result: Result<ChatMessage, Error>?

    @Atomic var unpinMessage_messageId: MessageId?
    @Atomic var unpinMessage_completion: ((Result<ChatMessage, Error>) -> Void)?
    @Atomic var unpinMessage_completion_result: Result<ChatMessage, Error>?

    @Atomic var restartFailedAttachmentUploading_id: AttachmentId?
    @Atomic var restartFailedAttachmentUploading_completion: ((Error?) -> Void)?
    @Atomic var restartFailedAttachmentUploading_completion_result: Result<Void, Error>?

    @Atomic var resendMessage_messageId: MessageId?
    @Atomic var resendMessage_completion: ((Error?) -> Void)?
    @Atomic var resendMessage_completion_result: Result<Void, Error>?

    @Atomic var dispatchEphemeralMessageAction_cid: ChannelId?
    @Atomic var dispatchEphemeralMessageAction_messageId: MessageId?
    @Atomic var dispatchEphemeralMessageAction_action: AttachmentAction?
    @Atomic var dispatchEphemeralMessageAction_completion: ((Error?) -> Void)?

    @Atomic var search_query: MessageSearchQuery?
    @Atomic var search_policy: UpdatePolicy?
    @Atomic var search_completion: ((Result<MessageSearchResults, Error>) -> Void)?
    @Atomic var search_completion_result: Result<MessageSearchResults, Error>?

    @Atomic var clearSearchResults_query: MessageSearchQuery?
    @Atomic var clearSearchResults_completion: ((Error?) -> Void)?

    @Atomic var translate_messageId: MessageId?
    @Atomic var translate_language: TranslationLanguage?
    @Atomic var translate_completion: ((Result<ChatMessage, Error>) -> Void)?
    @Atomic var translate_completion_result: Result<ChatMessage, Error>?

    @Atomic var updatePartialMessage_messageId: MessageId?
    @Atomic var updatePartialMessage_text: String?
    @Atomic var updatePartialMessage_attachments: [AnyAttachmentPayload]?
    @Atomic var updatePartialMessage_extraData: [String: RawJSON]?
    @Atomic var updatePartialMessage_completion: ((Result<ChatMessage, Error>) -> Void)?
    @Atomic var updatePartialMessage_completion_result: Result<ChatMessage, Error>?

    var markThreadRead_threadId: MessageId?
    var markThreadRead_cid: ChannelId?
    var markThreadRead_callCount = 0
    var markThreadRead_completion: ((Error?) -> Void)?

    var markThreadUnread_threadId: MessageId?
    var markThreadUnread_cid: ChannelId?
    var markThreadUnread_callCount = 0
    var markThreadUnread_completion: ((Error?) -> Void)?

    var updateThread_callCount = 0
    var updateThread_messageId: MessageId?
    var updateThread_request: ThreadPartialUpdateRequest?
    var updateThread_completion: ((Result<ChatThread, any Error>) -> Void)?

    var loadThread_callCount = 0
    var loadThread_query: ThreadQuery?
    var loadThread_completion: ((Result<ChatThread, any Error>) -> Void)?

    // Cleans up all recorded values
    func cleanUp() {
        getMessage_cid = nil
        getMessage_messageId = nil
        getMessage_completion = nil

        deleteMessage_messageId = nil
        deleteMessage_completion = nil
        deleteMessage_completion_result = nil

        deleteLocalAttachmentDownload_attachmentId = nil
        deleteLocalAttachmentDownload_completion_result = nil
        
        downloadAttachment_attachmentId = nil
        downloadAttachment_completion_result = nil
        
        editMessage_messageId = nil
        editMessage_text = nil
        editMessage_skipPush = nil
        editMessage_completion = nil

        createNewReply_cid = nil
        createNewReply_text = nil
        createNewReply_command = nil
        createNewReply_arguments = nil
        createNewReply_parentMessageId = nil
        createNewReply_attachments = nil
        createNewReply_mentionedUserIds = nil
        createNewReply_showReplyInChannel = nil
        createNewReply_isSilent = nil
        createNewReply_skipPush = nil
        createNewReply_skipEnrichUrl = nil
        createNewReply_extraData = nil
        createNewReply_completion = nil

        loadReplies_cid = nil
        loadReplies_messageId = nil
        loadReplies_pagination = nil
        loadReplies_completion = nil

        loadReactions_cid = nil
        loadReactions_messageId = nil
        loadReactions_pagination = nil
        loadReactions_completion = nil
        loadReactions_result = nil

        flagMessage_flag = nil
        flagMessage_messageId = nil
        flagMessage_cid = nil
        flagMessage_reason = nil
        flagMessage_extraData = nil
        flagMessage_completion = nil
        flagMessage_completion_result = nil

        addReaction_type = nil
        addReaction_score = nil
        addReaction_enforceUnique = nil
        addReaction_skipPush = nil
        addReaction_pushEmojiCode = nil
        addReaction_extraData = nil
        addReaction_messageId = nil
        addReaction_completion = nil
        addReaction_completion_result = nil

        deleteReaction_type = nil
        deleteReaction_messageId = nil
        deleteReaction_completion = nil
        deleteReaction_completion_result = nil

        pinMessage_pinning = nil
        pinMessage_messageId = nil
        pinMessage_completion = nil
        pinMessage_completion_result = nil

        unpinMessage_messageId = nil
        unpinMessage_completion = nil
        unpinMessage_completion_result = nil

        restartFailedAttachmentUploading_id = nil
        restartFailedAttachmentUploading_completion = nil
        restartFailedAttachmentUploading_completion_result = nil

        resendMessage_messageId = nil
        resendMessage_completion = nil
        resendMessage_completion_result = nil
        
        dispatchEphemeralMessageAction_cid = nil
        dispatchEphemeralMessageAction_messageId = nil
        dispatchEphemeralMessageAction_action = nil
        dispatchEphemeralMessageAction_completion = nil

        search_query = nil
        search_policy = nil
        search_completion = nil
        search_completion_result = nil

        clearSearchResults_query = nil
        clearSearchResults_completion = nil

        translate_messageId = nil
        translate_language = nil
        translate_completion = nil
        translate_completion_result = nil

        markThreadRead_threadId = nil
        markThreadRead_cid = nil
        markThreadRead_completion = nil

        markThreadUnread_threadId = nil
        markThreadUnread_cid = nil
        markThreadUnread_completion = nil

        updateThread_messageId = nil
        updateThread_request = nil
        updateThread_completion = nil

        loadThread_query = nil
        loadThread_completion = nil

        updatePartialMessage_messageId = nil
        updatePartialMessage_text = nil
        updatePartialMessage_attachments = nil
        updatePartialMessage_extraData = nil
        updatePartialMessage_completion = nil

        stopLiveLocationSharing_completion = nil
        updateLiveLocation_completion = nil
    }

    override func getMessage(cid: ChannelId, messageId: MessageId, completion: ((Result<ChatMessage, Error>) -> Void)? = nil) {
        getMessage_cid = cid
        getMessage_messageId = messageId
        getMessage_completion = completion
    }

    override func deleteMessage(messageId: MessageId, hard: Bool, deleteForMe: Bool? = nil, completion: ((Error?) -> Void)? = nil) {
        deleteMessage_messageId = messageId
        deleteMessage_hard = hard
        deleteMessage_deleteForMe = deleteForMe
        deleteMessage_completion = completion
        deleteMessage_completion_result?.invoke(with: completion)
    }
    
    override func deleteLocalAttachmentDownload(for attachmentId: AttachmentId, completion: @escaping ((any Error)?) -> Void) {
        deleteLocalAttachmentDownload_attachmentId = attachmentId
        deleteLocalAttachmentDownload_completion_result?.invoke(with: completion)
    }
    
    override func downloadAttachment<Payload>(
        _ attachment: ChatMessageAttachment<Payload>,
        completion: @escaping (Result<ChatMessageAttachment<Payload>, any Error>) -> Void
    ) where Payload: DownloadableAttachmentPayload {
        downloadAttachment_attachmentId = attachment.id
        switch downloadAttachment_completion_result {
        case .success(let anyAttachment):
            if let result = anyAttachment.attachment(payloadType: Payload.self) {
                completion(.success(result))
            } else {
                completion(.failure(TestError()))
            }
        case .failure(let error):
            completion(.failure(error))
        case nil:
            break
        }
    }
    
    override func editMessage(
        messageId: MessageId,
        text: String,
        skipEnrichUrl: Bool,
        skipPush: Bool,
        attachments: [AnyAttachmentPayload] = [],
        restrictedVisibility: [UserId] = [],
        extraData: [String: RawJSON]? = nil,
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        editMessage_messageId = messageId
        editMessage_text = text
        editMessage_skipEnrichUrl = skipEnrichUrl
        editMessage_skipPush = skipPush
        editMessage_restrictedVisibility = restrictedVisibility
        editMessage_attachments = attachments
        editMessage_extraData = extraData
        editMessage_completion = completion
    }

    override func resendMessage(with messageId: MessageId, completion: @escaping (Error?) -> Void) {
        resendMessage_messageId = messageId
        resendMessage_completion = completion
        resendMessage_completion_result?.invoke(with: completion)
    }

    override func updateLiveLocation(
        messageId: MessageId,
        locationInfo: LocationInfo,
        completion: @escaping ((Result<SharedLocation, any Error>) -> Void)
    ) {
        updateLiveLocation_messageId = messageId
        updateLiveLocation_locationInfo = locationInfo
        updateLiveLocation_completion = completion
    }

    override func stopLiveLocationSharing(
        messageId: MessageId,
        completion: @escaping ((Result<SharedLocation, any Error>) -> Void)
    ) {
        stopLiveLocationSharing_messageId = messageId
        stopLiveLocationSharing_completion = completion
    }

    override func createNewReply(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning?,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: MessageId?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        extraData: [String: RawJSON],
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        createNewReply_cid = cid
        createNewReply_text = text
        createNewReply_command = command
        createNewReply_arguments = arguments
        createNewReply_parentMessageId = parentMessageId
        createNewReply_attachments = attachments
        createNewReply_mentionedUserIds = mentionedUserIds
        createNewReply_showReplyInChannel = showReplyInChannel
        createNewReply_isSilent = isSilent
        createNewReply_skipPush = skipPush
        createNewReply_skipEnrichUrl = skipEnrichUrl
        createNewReply_quotedMessageId = quotedMessageId
        createNewReply_pinning = pinning
        createNewReply_extraData = extraData
        createNewReply_completion = completion
    }

    override func loadReplies(
        cid: ChannelId,
        messageId: MessageId,
        pagination: MessagesPagination,
        paginationStateHandler: MessagesPaginationStateHandling,
        completion: ((Result<MessageRepliesPayload, Error>) -> Void)? = nil
    ) {
        loadReplies_callCount += 1
        loadReplies_cid = cid
        loadReplies_messageId = messageId
        loadReplies_pagination = pagination
        loadReplies_paginationStateHandler = paginationStateHandler
        loadReplies_completion = completion
    }

    override func loadReactions(
        cid: ChannelId,
        messageId: MessageId,
        pagination: Pagination,
        completion: ((Result<[ChatMessageReaction], Error>) -> Void)? = nil
    ) {
        loadReactions_cid = cid
        loadReactions_messageId = messageId
        loadReactions_pagination = pagination
        loadReactions_completion = completion
        if let loadReactionsResult = loadReactions_result {
            completion?(loadReactionsResult)
        }
    }

    override func flagMessage(
        _ flag: Bool,
        with messageId: MessageId,
        in cid: ChannelId,
        reason: String?,
        extraData: [String: RawJSON]?,
        completion: ((Error?) -> Void)? = nil
    ) {
        flagMessage_flag = flag
        flagMessage_messageId = messageId
        flagMessage_cid = cid
        flagMessage_reason = reason
        flagMessage_extraData = extraData
        flagMessage_completion = completion
        flagMessage_completion_result?.invoke(with: completion)
    }

    override func addReaction(
        _ type: MessageReactionType,
        score: Int,
        enforceUnique: Bool,
        skipPush: Bool,
        pushEmojiCode: String?,
        extraData: [String: RawJSON],
        messageId: MessageId,
        completion: ((Error?) -> Void)? = nil
    ) {
        addReaction_type = type
        addReaction_score = score
        addReaction_enforceUnique = enforceUnique
        addReaction_skipPush = skipPush
        addReaction_pushEmojiCode = pushEmojiCode
        addReaction_extraData = extraData
        addReaction_messageId = messageId
        addReaction_completion = completion
        addReaction_completion_result?.invoke(with: completion)
    }

    override func deleteReaction(
        _ type: MessageReactionType,
        messageId: MessageId,
        completion: ((Error?) -> Void)? = nil
    ) {
        deleteReaction_type = type
        deleteReaction_messageId = messageId
        deleteReaction_completion = completion
        deleteReaction_completion_result?.invoke(with: completion)
    }

    override func pinMessage(messageId: MessageId, pinning: MessagePinning, completion: ((Result<ChatMessage, any Error>) -> Void)? = nil) {
        pinMessage_messageId = messageId
        pinMessage_pinning = pinning
        pinMessage_completion = completion
        pinMessage_completion_result?.invoke(with: completion)
    }

    override func unpinMessage(messageId: MessageId, completion: ((Result<ChatMessage, any Error>) -> Void)? = nil) {
        unpinMessage_messageId = messageId
        unpinMessage_completion = completion
        unpinMessage_completion_result?.invoke(with: completion)
    }

    override func restartFailedAttachmentUploading(
        with id: AttachmentId,
        completion: @escaping (Error?) -> Void
    ) {
        restartFailedAttachmentUploading_id = id
        restartFailedAttachmentUploading_completion = completion
        restartFailedAttachmentUploading_completion_result?.invoke(with: completion)
    }

    override func dispatchEphemeralMessageAction(
        cid: ChannelId,
        messageId: MessageId,
        action: AttachmentAction,
        completion: ((Error?) -> Void)? = nil
    ) {
        dispatchEphemeralMessageAction_cid = cid
        dispatchEphemeralMessageAction_messageId = messageId
        dispatchEphemeralMessageAction_action = action
        dispatchEphemeralMessageAction_completion = completion
    }
    
    override func search(
        query: MessageSearchQuery,
        policy: UpdatePolicy = .merge,
        completion: ((Result<MessageSearchResults, Error>) -> Void)? = nil
    ) {
        search_query = query
        search_policy = policy
        search_completion = completion
        search_completion_result?.invoke(with: completion)
    }

    override func clearSearchResults(
        for query: MessageSearchQuery,
        completion: ((Error?) -> Void)? = nil
    ) {
        clearSearchResults_query = query
        clearSearchResults_completion = completion
    }

    override func translate(
        messageId: MessageId,
        to language: TranslationLanguage,
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        translate_messageId = messageId
        translate_language = language
        translate_completion = completion
        translate_completion_result?.invoke(with: completion)
    }

    override func markThreadRead(cid: ChannelId, threadId: MessageId, completion: @escaping (((any Error)?) -> Void)) {
        markThreadRead_cid = cid
        markThreadRead_threadId = threadId
        markThreadRead_callCount += 1
        markThreadRead_completion = completion
    }

    override func markThreadUnread(cid: ChannelId, threadId: MessageId, completion: @escaping (((any Error)?) -> Void)) {
        markThreadUnread_cid = cid
        markThreadUnread_threadId = threadId
        markThreadUnread_callCount += 1
        markThreadUnread_completion = completion
    }

    override func updateThread(
        for messageId: MessageId,
        request: ThreadPartialUpdateRequest,
        completion: @escaping ((Result<ChatThread, any Error>) -> Void)
    ) {
        updateThread_callCount += 1
        updateThread_messageId = messageId
        updateThread_request = request
        updateThread_completion = completion
    }

    override func loadThread(
        query: ThreadQuery,
        completion: @escaping ((Result<ChatThread, any Error>) -> Void)
    ) {
        loadThread_callCount += 1
        loadThread_query = query
        loadThread_completion = completion
    }

    override func updatePartialMessage(
        messageId: MessageId,
        text: String? = nil,
        attachments: [AnyAttachmentPayload]? = nil,
        extraData: [String: RawJSON]? = nil,
        unset: [String]? = nil,
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        updatePartialMessage_messageId = messageId
        updatePartialMessage_text = text
        updatePartialMessage_attachments = attachments
        updatePartialMessage_extraData = extraData
        updatePartialMessage_completion = completion
        updatePartialMessage_completion_result?.invoke(with: completion)
    }
}

extension MessageUpdater.MessageSearchResults {
    static func empty() -> Self {
        .make(api: [], next: nil, models: [])
    }
    
    static func make(api apiMessages: [MessagePayload.Boxed] = [], next: String? = nil, models: [ChatMessage] = []) -> Self {
        MessageUpdater.MessageSearchResults(payload: MessageSearchResultsPayload(results: apiMessages, next: next), models: models)
    }
}
