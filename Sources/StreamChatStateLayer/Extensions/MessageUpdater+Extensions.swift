//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension MessageUpdater {
    func addReaction(_ type: MessageReactionType, score: Int, enforceUnique: Bool, extraData: [String: RawJSON], messageId: MessageId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            addReaction(type, score: score, enforceUnique: enforceUnique, extraData: extraData, messageId: messageId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func clearSearchResults(for query: MessageSearchQuery) async throws {
        try await withCheckedThrowingContinuation { continuation in
            clearSearchResults(for: query) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func createNewReply(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning?,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: MessageId?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        extraData: [String: RawJSON]
    ) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            createNewReply(
                in: cid,
                messageId: messageId,
                text: text,
                pinning: pinning,
                command: command,
                arguments: arguments,
                parentMessageId: parentMessageId,
                attachments: attachments,
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: showReplyInChannel,
                isSilent: isSilent,
                quotedMessageId: quotedMessageId,
                skipPush: skipPush,
                skipEnrichUrl: skipEnrichUrl,
                extraData: extraData
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func deleteMessage(messageId: MessageId, hard: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteMessage(messageId: messageId, hard: hard) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func deleteReaction(_ type: MessageReactionType, messageId: MessageId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteReaction(type, messageId: messageId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func dispatchEphemeralMessageAction(cid: ChannelId, messageId: MessageId, action: AttachmentAction) async throws {
        try await withCheckedThrowingContinuation { continuation in
            dispatchEphemeralMessageAction(cid: cid, messageId: messageId, action: action) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func editMessage(messageId: MessageId, text: String, skipEnrichUrl: Bool, attachments: [AnyAttachmentPayload] = [], extraData: [String: RawJSON]? = nil) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            editMessage(messageId: messageId, text: text, skipEnrichUrl: skipEnrichUrl, attachments: attachments, extraData: extraData) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func flagMessage(_ flag: Bool, with messageId: MessageId, in cid: ChannelId, reason: String?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            flagMessage(flag, with: messageId, in: cid, reason: reason) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func getMessage(cid: ChannelId, messageId: MessageId) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            getMessage(cid: cid, messageId: messageId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func loadReactions(cid: ChannelId, messageId: MessageId, pagination: Pagination) async throws -> [ChatMessageReaction] {
        try await withCheckedThrowingContinuation { continuation in
            loadReactions(cid: cid, messageId: messageId, pagination: pagination) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @discardableResult func loadReplies(cid: ChannelId, messageId: MessageId, pagination: MessagesPagination, paginationStateHandler: MessagesPaginationStateHandling) async throws -> MessageRepliesPayload {
        try await withCheckedThrowingContinuation { continuation in
            loadReplies(cid: cid, messageId: messageId, pagination: pagination, paginationStateHandler: paginationStateHandler) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func pinMessage(messageId: MessageId, pinning: MessagePinning) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            pinMessage(messageId: messageId, pinning: pinning) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func resendAttachment(with id: AttachmentId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            restartFailedAttachmentUploading(with: id) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func resendMessage(with messageId: MessageId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            resendMessage(with: messageId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func search(query: MessageSearchQuery, policy: UpdatePolicy) async throws -> MessageSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            search(query: query, policy: policy) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func translate(messageId: MessageId, to language: TranslationLanguage) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            translate(messageId: messageId, to: language) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func unpinMessage(messageId: MessageId) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            unpinMessage(messageId: messageId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: -
    
    func loadReplies(for parentMessageId: MessageId, pagination: MessagesPagination, cid: ChannelId, paginationStateHandler: MessagesPaginationStateHandling) async throws -> [ChatMessage] {
        let payload = try await loadReplies(cid: cid, messageId: parentMessageId, pagination: pagination, paginationStateHandler: paginationStateHandler)
        guard let fromDate = payload.messages.first?.createdAt else { return [] }
        guard let toDate = payload.messages.last?.createdAt else { return [] }
        return try await repository.replies(from: fromDate, to: toDate, in: parentMessageId)
    }
    
    func loadReplies(for parentMessageId: MessageId, before replyId: MessageId?, limit: Int?, cid: ChannelId, paginationStateHandler: MessagesPaginationStateHandling) async throws {
        guard !paginationStateHandler.state.hasLoadedAllPreviousMessages else { return }
        guard !paginationStateHandler.state.isLoadingPreviousMessages else { return }
        guard let replyId = replyId ?? paginationStateHandler.state.oldestFetchedMessage?.id else {
            throw ClientError.MessageEmptyReplies()
        }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .lessThan(replyId))
        try await loadReplies(cid: cid, messageId: parentMessageId, pagination: pagination, paginationStateHandler: paginationStateHandler)
    }
    
    func loadReplies(for parentMessageId: MessageId, after replyId: MessageId?, limit: Int?, cid: ChannelId, paginationStateHandler: MessagesPaginationStateHandling) async throws {
        guard !paginationStateHandler.state.hasLoadedAllNextMessages else { return }
        guard !paginationStateHandler.state.isLoadingNextMessages else { return }
        guard let replyId = replyId ?? paginationStateHandler.state.newestFetchedMessage?.id else {
            throw ClientError.MessageEmptyReplies()
        }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .greaterThan(replyId))
        try await loadReplies(cid: cid, messageId: parentMessageId, pagination: pagination, paginationStateHandler: paginationStateHandler)
    }
    
    func loadReplies(for parentMessageId: MessageId, around replyId: MessageId, limit: Int?, cid: ChannelId, paginationStateHandler: MessagesPaginationStateHandling) async throws {
        guard !paginationStateHandler.state.isLoadingMiddleMessages else { return }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .around(replyId))
        try await loadReplies(cid: cid, messageId: parentMessageId, pagination: pagination, paginationStateHandler: paginationStateHandler)
    }
}
