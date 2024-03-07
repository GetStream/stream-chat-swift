//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a ``ChatMessage`` and its state.
@available(iOS 13.0, *)
public final class MessageState: ObservableObject {
    private let chat: Chat
    private let messageOrder: MessageOrdering
    private let observer: Observer

    let replyPaginationHandler: MessagesPaginationStateHandling
    
    init(message: ChatMessage, chat: Chat, messageOrder: MessageOrdering, database: DatabaseContainer, replyPaginationHandler: MessagesPaginationStateHandling) {
        self.chat = chat
        self.message = message
        self.messageOrder = messageOrder
        self.replyPaginationHandler = replyPaginationHandler
        observer = Observer(messageId: message.id, database: database)
        observer.start(
            with: .init(
                messageDidChange: { [weak self] in await self?.setValue($0, for: \.message) },
                reactionsDidChange: { [weak self] in await self?.setValue($0, for: \.reactions) },
                repliesDidChange: { [weak self] in await self?.setValue($0, for: \.replies) }
            )
        )
    }
    
    var messageId: MessageId { message.id }
    
    var replyPaginationState: MessagesPaginationState {
        replyPaginationHandler.state
    }
    
    // MARK: - Chat Message
    
    /// The chat message being observed.
    @Published public private(set) var message: ChatMessage
    
    // MARK: - Reactions
    
    /// An array of loaded message reactions sorted by ``ChatMessageReaction.updatedAt`` with descending order.
    ///
    /// Use ``Chat.loadReactions(of:pagination:)`` for loading more reaactions.
    @Published public private(set) var reactions = [ChatMessageReaction]()
    
    // MARK: - Replies
    
    /// An array of loaded replies sorted by ``MessageOrdering``.
    @Published public private(set) var replies = [ChatMessage]()
    
    /// A Boolean value that returns whether the oldest replies have all been loaded or not.
    public var hasLoadedAllPreviousReplies: Bool {
        replyPaginationState.hasLoadedAllPreviousMessages
    }
    
    /// A Boolean value that returns whether the newest replies have all been loaded or not.
    public var hasLoadedAllNextReplies: Bool {
        replyPaginationState.hasLoadedAllNextMessages
    }

    /// A Boolean value that returns whether the channel is currently loading previous (old) replies.
    public var isLoadingPreviousReplies: Bool {
        replyPaginationState.isLoadingPreviousMessages
    }

    /// A Boolean value that returns whether the channel is currently loading a page around a reply.
    public var isLoadingMiddleReplies: Bool {
        replyPaginationState.isLoadingMiddleMessages
    }

    /// A Boolean value that returns whether the channel is currently loading next (new) replies.
    public var isLoadingNextReplies: Bool {
        replyPaginationState.isLoadingNextMessages
    }
    
    // MARK: - Mutating the State
    
    // Force main actor when accessing the state.
    @MainActor func value<Value>(forKeyPath keyPath: KeyPath<MessageState, Value>) -> Value {
        self[keyPath: keyPath]
    }
    
    // Force mutations on main actor since ChatState is meant to be used by UI.
    @MainActor func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<MessageState, Value>) {
        self[keyPath: keyPath] = value
    }
}
