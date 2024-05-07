//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension ChannelUpdater {
    func acceptInvite(cid: ChannelId, message: String?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            acceptInvite(cid: cid, message: message) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func addMembers(currentUserId: UserId? = nil, cid: ChannelId, userIds: Set<UserId>, message: String? = nil, hideHistory: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            addMembers(currentUserId: currentUserId, cid: cid, userIds: userIds, message: message, hideHistory: hideHistory) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func channelWatchers(for query: ChannelWatcherListQuery) async throws -> [ChatUser] {
        let payload = try await withCheckedThrowingContinuation { continuation in
            channelWatchers(query: query) { result in
                continuation.resume(with: result)
            }
        }
        guard let ids = payload.watchers?.map(\.id) else { return [] }
        return try await database.read { context in
            try ids.compactMap { try UserDTO.load(id: $0, context: context)?.asModel() }
        }
    }
    
    func createNewMessage(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning? = nil,
        isSilent: Bool,
        command: String?,
        arguments: String?,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId],
        quotedMessageId: MessageId?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        extraData: [String: RawJSON]
    ) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            createNewMessage(
                in: cid,
                messageId: messageId,
                text: text,
                pinning: pinning,
                isSilent: isSilent,
                command: command,
                arguments: arguments,
                attachments: attachments,
                mentionedUserIds: mentionedUserIds,
                quotedMessageId: quotedMessageId,
                skipPush: skipPush,
                skipEnrichUrl: skipEnrichUrl,
                extraData: extraData
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func deleteChannel(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteChannel(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func deleteFile(in cid: ChannelId, url: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteFile(in: cid, url: url) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func deleteImage(in cid: ChannelId, url: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteImage(in: cid, url: url) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func enableSlowMode(cid: ChannelId, cooldownDuration: Int) async throws {
        try await withCheckedThrowingContinuation { continuation in
            enableSlowMode(cid: cid, cooldownDuration: cooldownDuration) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func enrichUrl(_ url: URL) async throws -> LinkAttachmentPayload {
        try await withCheckedThrowingContinuation { continuation in
            enrichUrl(url) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func freezeChannel(_ freeze: Bool, cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            freezeChannel(freeze, cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func hideChannel(cid: ChannelId, clearHistory: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            hideChannel(cid: cid, clearHistory: clearHistory) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func inviteMembers(cid: ChannelId, userIds: Set<UserId>) async throws {
        try await withCheckedThrowingContinuation { continuation in
            inviteMembers(cid: cid, userIds: userIds) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func loadPinnedMessages(in cid: ChannelId, query: PinnedMessagesQuery) async throws -> [ChatMessage] {
        try await withCheckedThrowingContinuation { continuation in
            loadPinnedMessages(in: cid, query: query) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func markRead(cid: ChannelId, userId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            markRead(cid: cid, userId: userId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    @discardableResult
    func markUnread(cid: ChannelId, userId: UserId, from messageId: MessageId, lastReadMessageId: MessageId?) async throws -> ChatChannel {
        try await withCheckedThrowingContinuation { continuation in
            markUnread(cid: cid, userId: userId, from: messageId, lastReadMessageId: lastReadMessageId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func muteChannel(_ mute: Bool, cid: ChannelId, expiration: Int? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            muteChannel(cid: cid, mute: mute, expiration: expiration) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func rejectInvite(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            rejectInvite(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func removeMembers(currentUserId: UserId? = nil, cid: ChannelId, userIds: Set<UserId>, message: String? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            removeMembers(currentUserId: currentUserId, cid: cid, userIds: userIds, message: message) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func showChannel(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            showChannel(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func startWatching(cid: ChannelId, isInRecoveryMode: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            startWatching(cid: cid, isInRecoveryMode: isInRecoveryMode) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func stopWatching(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stopWatching(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func truncateChannel(cid: ChannelId, skipPush: Bool, hardDelete: Bool, systemMessage: String?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            truncateChannel(cid: cid, skipPush: skipPush, hardDelete: hardDelete, systemMessage: systemMessage) { error in
                continuation.resume(with: error)
            }
        }
    }

    @discardableResult func update(
        channelQuery: ChannelQuery,
        memberSorting: [Sorting<ChannelMemberListSortingKey>] = []
    ) async throws -> ChannelPayload {
        // Just populate the closure since we select the endpoint based on it.
        let useCreateEndpoint: ((ChannelId) -> Void)? = channelQuery.cid == nil ? { _ in } : nil
        let actions = ChannelUpdateActions(
            memberListSorting: memberSorting,
            resetMembers: true,
            resetWatchers: true
        )
        return try await withCheckedThrowingContinuation { continuation in
            update(
                channelQuery: channelQuery,
                isInRecoveryMode: false,
                onChannelCreated: useCreateEndpoint,
                actions: actions,
                completion: continuation.resume(with:)
            )
        }
    }
    
    func update(channelPayload: ChannelEditDetailPayload) async throws {
        try await withCheckedThrowingContinuation { continuation in
            updateChannel(channelPayload: channelPayload) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func updatePartial(channelPayload: ChannelEditDetailPayload, unsetProperties: [String]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            partialChannelUpdate(updates: channelPayload, unsetProperties: unsetProperties) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func uploadFile(type: AttachmentType, localFileURL: URL, cid: ChannelId, progress: ((Double) -> Void)? = nil) async throws -> UploadedAttachment {
        try await withCheckedThrowingContinuation { continuation in
            uploadFile(type: type, localFileURL: localFileURL, cid: cid, progress: progress) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: -
    
    func loadMessages(with channelQuery: ChannelQuery, pagination: MessagesPagination) async throws -> [ChatMessage] {
        let payload = try await update(channelQuery: channelQuery.withPagination(pagination))
        guard let cid = channelQuery.cid else { return [] }
        guard let fromDate = payload.messages.first?.createdAt else { return [] }
        guard let toDate = payload.messages.last?.createdAt else { return [] }
        return try await messageRepository.messages(from: fromDate, to: toDate, in: cid)
    }
    
    func loadMessages(before messageId: MessageId?, limit: Int?, channelQuery: ChannelQuery, loaded: StreamCollection<ChatMessage>) async throws {
        guard !paginationState.isLoadingPreviousMessages else { return }
        guard !paginationState.hasLoadedAllPreviousMessages else { return }
        let lastLocalMessageId: () -> MessageId? = { loaded.last { !$0.isLocalOnly }?.id }
        guard let messageId = messageId ?? paginationState.oldestFetchedMessage?.id ?? lastLocalMessageId() else {
            throw ClientError.ChannelEmptyMessages()
        }
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: limit, parameter: .lessThan(messageId))
        try await update(channelQuery: channelQuery.withPagination(pagination))
    }

    func loadMessages(after messageId: MessageId?, limit: Int?, channelQuery: ChannelQuery, loaded: StreamCollection<ChatMessage>) async throws {
        guard !paginationState.isLoadingNextMessages else { return }
        guard !paginationState.hasLoadedAllNextMessages else { return }
        guard let messageId = messageId ?? paginationState.newestFetchedMessage?.id ?? loaded.first?.id else {
            throw ClientError.ChannelEmptyMessages()
        }
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: limit, parameter: .greaterThan(messageId))
        try await update(channelQuery: channelQuery.withPagination(pagination))
    }
        
    func loadMessages(around messageId: MessageId, limit: Int?, channelQuery: ChannelQuery, loaded: StreamCollection<ChatMessage>) async throws {
        guard !paginationState.isLoadingMiddleMessages else { return }
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: limit, parameter: .around(messageId))
        try await update(channelQuery: channelQuery.withPagination(pagination))
    }
}

extension ChannelQuery {
    func withPagination(_ pagination: MessagesPagination) -> Self {
        var result = self
        result.pagination = pagination
        return result
    }
    
    func withOptions(forWatching watch: Bool) -> Self {
        var result = self
        result.options = watch ? .all : .state
        return result
    }
}
