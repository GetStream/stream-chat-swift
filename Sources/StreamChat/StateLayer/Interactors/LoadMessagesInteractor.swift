//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0.0, *)
final class LoadMessagesInteractor {
    private let cid: ChannelId
    private let channelUpdater: ChannelUpdater
    private let messageRepository: MessageRepository
    private let order: MessageOrdering
    
    init(cid: ChannelId, order: MessageOrdering, channelUpdater: ChannelUpdater, messageRepository: MessageRepository) {
        self.cid = cid
        self.channelUpdater = channelUpdater
        self.messageRepository = messageRepository
        self.order = order
    }
    
    private var canLoad: Bool {
        let state = channelUpdater.paginationStateHandler.state
        return !state.hasLoadedAllPreviousMessages && !state.isLoadingPreviousMessages
    }
    
    private func defaultPrecedingMessage(for proposed: MessageId?, in state: ChatState) async -> MessageId? {
        if let proposed {
            return proposed
        } else if let id = channelUpdater.paginationState.oldestFetchedMessage?.id {
            return id
        } else {
            return await state.oldestAPIMessageId
        }
    }
    
    private func defaultSucceedingMessage(for proposed: MessageId?, in state: ChatState) async -> MessageId? {
        if let proposed {
            return proposed
        } else if let id = channelUpdater.paginationState.newestFetchedMessage?.id {
            return id
        } else {
            return await state.newestAPIMessageId
        }
    }
    
    private func loadMessages(to state: ChatState, with channelQuery: ChannelQuery) async throws {
        guard let pagination = channelQuery.pagination else {
            throw ClientError.Unknown("Pagination is not set")
        }
        let resetsToLocal: Bool = pagination.parameter == nil || pagination.parameter?.isJumpingToMessage ?? false
        let payload = try await channelUpdater.update(channelQuery: channelQuery, isInRecoveryMode: false)
        let messageIds = payload.messages.map(\.id)
        let messages = try await messageRepository.messages(for: messageIds)
        // TODO: Missing filtering: use channel messages predicate with ids or timestamps
        await state.insertPaginatedMessages(messages, resetToLocalOnly: resetsToLocal)
    }
    
    func loadMorePrecedingMessages(to state: ChatState, channelQuery: ChannelQuery, before messageId: MessageId?, limit: Int?) async throws {
        guard canLoad else { return }
        guard let messageId = await defaultPrecedingMessage(for: messageId, in: state) else {
            throw ClientError.ChannelEmptyMessages()
        }
        let pageSize = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .lessThan(messageId))
        try await loadMessages(to: state, with: channelQuery.withPagination(pagination))
    }
    
    func loadMoreSucceedingMessages(to state: ChatState, with channelQuery: ChannelQuery, after messageId: MessageId?, limit: Int?) async throws {
        guard canLoad else { return }
        guard let messageId = await defaultSucceedingMessage(for: messageId, in: state) else {
            throw ClientError.ChannelEmptyMessages()
        }
        let pageSize = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .greaterThan(messageId))
        try await loadMessages(to: state, with: channelQuery.withPagination(pagination))
    }
    
    func loadMoreMessages(to state: ChatState, with channelQuery: ChannelQuery, around messageId: MessageId, limit: Int?) async throws {
        guard canLoad else { return }
        let pageSize = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .around(messageId))
        try await loadMessages(to: state, with: channelQuery.withPagination(pagination))
    }

    func loadFirstPage(to state: ChatState, with channelQuery: ChannelQuery) async throws {
        guard canLoad else { return }
        let pageSize = channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: nil)
        try await loadMessages(to: state, with: channelQuery.withPagination(pagination))
    }
}

// MARK: -

@available(iOS 13.0, *)
private extension ChatState {
    @MainActor var oldestAPIMessageId: MessageId? {
        orderedMessages.ascendingSortedMessages.first(where: { !$0.isLocalOnly })?.id
    }
    
    @MainActor var newestAPIMessageId: MessageId? {
        orderedMessages.ascendingSortedMessages.last(where: { !$0.isLocalOnly })?.id
    }
}

private extension ChannelQuery {
    func withPagination(_ pagination: MessagesPagination) -> Self {
        var query = self
        query.pagination = pagination
        return query
    }
}
