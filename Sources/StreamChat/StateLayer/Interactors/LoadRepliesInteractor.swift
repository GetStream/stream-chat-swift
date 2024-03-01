//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct LoadRepliesInteractor {
    private let cid: ChannelId
    private let messageRepository: MessageRepository
    private let messageUpdater: MessageUpdater
    private let order: MessageOrdering
    
    init(cid: ChannelId, order: MessageOrdering, messageUpdater: MessageUpdater, messageRepository: MessageRepository) {
        self.cid = cid
        self.messageRepository = messageRepository
        self.messageUpdater = messageUpdater
        self.order = order
    }
    
    private func defaultPreviousMessage(for proposed: MessageId?, in state: MessageState) async -> MessageId? {
        if let proposed {
            return proposed
        } else if let id = state.replyPaginationHandler.state.oldestFetchedMessage?.id {
            return id
        } else {
            return await state.oldestAPIMessageId
        }
    }
    
    private func defaultNextMessage(for proposed: MessageId?, in state: MessageState) async -> MessageId? {
        if let proposed {
            return proposed
        } else if let id = state.replyPaginationState.newestFetchedMessage?.id {
            return id
        } else {
            return await state.newestAPIMessageId
        }
    }
    
    @discardableResult func loadReplies(to state: MessageState, pagination: MessagesPagination) async throws -> [ChatMessage] {
        let resetToLocalOnly: Bool = pagination.parameter == nil || pagination.parameter?.isJumpingToMessage ?? false
        let payload = try await messageUpdater.loadReplies(cid: cid, messageId: state.messageId, pagination: pagination, paginationStateHandler: state.replyPaginationHandler)
        guard let fromDate = payload.messages.first?.createdAt else { return [] }
        guard let toDate = payload.messages.last?.createdAt else { return [] }
        let newSortedMessages = try await messageRepository.replies(from: fromDate, to: toDate, in: state.messageId)
        let merged = await state.orderedReplies.withInsertingPaginated(newSortedMessages, resetToLocalOnly: resetToLocalOnly)
        await state.setSortedReplies(merged)
        return newSortedMessages
    }
    
    func loadRepliesFirstPage(to state: MessageState, limit: Int?) async throws {
        let pageSize = limit ?? .messagesPageSize
        try await loadReplies(to: state, pagination: MessagesPagination(pageSize: pageSize))
    }
    
    func loadReplies(to state: MessageState, before replyId: MessageId?, limit: Int?) async throws {
        guard !state.replyPaginationState.hasLoadedAllPreviousMessages && !state.replyPaginationState.isLoadingPreviousMessages else { return }
        guard let replyId = await defaultPreviousMessage(for: replyId, in: state) else {
            throw ClientError.ChannelEmptyMessages()
        }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .lessThan(replyId))
        try await loadReplies(to: state, pagination: pagination)
    }
    
    func loadReplies(to state: MessageState, after replyId: MessageId?, limit: Int?) async throws {
        guard !state.replyPaginationState.hasLoadedAllNextMessages && !state.replyPaginationState.isLoadingNextMessages else { return }
        guard let replyId = await defaultNextMessage(for: replyId, in: state) else {
            throw ClientError.ChannelEmptyMessages()
        }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .greaterThan(replyId))
        try await loadReplies(to: state, pagination: pagination)
    }
    
    func loadReplies(to state: MessageState, around replyId: MessageId, limit: Int?) async throws {
        guard !state.replyPaginationState.isLoadingMiddleMessages else { return }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .around(replyId))
        try await loadReplies(to: state, pagination: pagination)
    }
}

// MARK: -

@available(iOS 13.0, *)
private extension MessageState {
    @MainActor var oldestAPIMessageId: MessageId? {
        orderedReplies.ascendingSortedMessages.first(where: { !$0.isLocalOnly })?.id
    }
    
    @MainActor var newestAPIMessageId: MessageId? {
        orderedReplies.ascendingSortedMessages.last(where: { !$0.isLocalOnly })?.id
    }
}
