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
        await state.insertMessages(messages, resetsToLocal: resetsToLocal)
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

extension MessageOrdering {
    var isReversed: Bool {
        switch self {
        case .bottomToTop: return true
        case .topToBottom: return false
        }
    }
}

@available(iOS 13.0, *)
private extension ChatState {
    @MainActor var oldestAPIMessageId: MessageId? {
        let messages = messageOrder.isReversed ? messages.reversed() : messages
        return messages.first(where: { !$0.isLocalOnly })?.id
    }
    
    @MainActor var newestAPIMessageId: MessageId? {
        let messages = messageOrder.isReversed ? messages.reversed() : messages
        return messages.last(where: { !$0.isLocalOnly })?.id
    }
    
    @MainActor func insertMessages(_ newMessages: [ChatMessage], resetsToLocal: Bool) {
        var messages = self.messages
        if resetsToLocal {
            messages = messages.filter { $0.isLocalOnly }
        }
        switch messageOrder {
        case .topToBottom:
            setMessages(ChatState.mergeSorted(messages.reversed(), newMessages).reversed())
        case .bottomToTop:
            setMessages(ChatState.mergeSorted(messages, newMessages))
        }
    }
    
    /// Merges a sorted array into a already sorted array with ignoring duplicates. The resulting array keeps its sort order.
    static func mergeSorted(_ currentElements: [ChatMessage], _ newElements: [ChatMessage]) -> [ChatMessage] {
        func insert(_ merged: inout [ChatMessage], newElement: ChatMessage) {
            // Prefer the new element when detecting duplicates (e.g. API fetch tries to insert updated message)
            if merged.last?.id == newElement.id {
                merged.removeLast()
            }
            merged.append(newElement)
        }

        var merged = [ChatMessage]()
        merged.reserveCapacity(currentElements.count + newElements.count)
        
        var currentElementIndex = 0
        var newElementIndex = 0
        while currentElementIndex < currentElements.count, newElementIndex < newElements.count {
            if currentElements[currentElementIndex].createdAt < newElements[newElementIndex].createdAt {
                insert(&merged, newElement: currentElements[currentElementIndex])
                currentElementIndex += 1
            } else {
                insert(&merged, newElement: newElements[newElementIndex])
                newElementIndex += 1
            }
        }
        while currentElementIndex < currentElements.count {
            insert(&merged, newElement: currentElements[currentElementIndex])
            currentElementIndex += 1
        }
        while newElementIndex < newElements.count {
            insert(&merged, newElement: newElements[newElementIndex])
            newElementIndex += 1
        }
        return merged
    }
}

private extension ChannelQuery {
    func withPagination(_ pagination: MessagesPagination) -> Self {
        var query = self
        query.pagination = pagination
        return query
    }
}
