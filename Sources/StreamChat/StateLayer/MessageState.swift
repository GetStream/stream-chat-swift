//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a ``ChatMessage`` and its state.
@MainActor public final class MessageState: ObservableObject {
    private let messageOrder: MessageOrdering
    private let observer: Observer

    let replyPaginationHandler: MessagesPaginationStateHandling
    
    init(
        message: ChatMessage,
        messageOrder: MessageOrdering,
        database: DatabaseContainer,
        clientConfig: ChatClientConfig,
        replyPaginationHandler: MessagesPaginationStateHandling
    ) {
        self.message = message
        self.messageOrder = messageOrder
        self.replyPaginationHandler = replyPaginationHandler
        observer = Observer(
            messageId: message.id,
            messageOrder: messageOrder,
            database: database,
            clientConfig: clientConfig
        )
        let initial = observer.start(
            with: .init(
                messageDidChange: { [weak self] in self?.message = $0 },
                reactionsDidChange: { [weak self] in self?.reactions = $0 },
                repliesDidChange: { [weak self] in self?.replies = $0 }
            )
        )
        if let message = initial.message {
            self.message = message
        }
        reactions = initial.reactions
        replies = initial.replies
    }
    
    var replyPaginationState: MessagesPaginationState {
        replyPaginationHandler.state
    }
    
    // MARK: - Chat Message
    
    /// The chat message being observed.
    @Published public private(set) var message: ChatMessage
    
    // MARK: - Reactions
    
    /// An array of loaded message reactions sorted by ``ChatMessageReaction/updatedAt`` with descending order.
    ///
    /// Use ``Chat/loadReactions(of:pagination:)`` for loading more reactions.
    @Published public private(set) var reactions = StreamCollection<ChatMessageReaction>([])
    
    // MARK: - Replies
    
    /// An array of loaded replies sorted by ``MessageOrdering``.
    @Published public internal(set) var replies = StreamCollection<ChatMessage>([])
    
    /// A Boolean value that returns whether the oldest replies have all been loaded or not.
    public var hasLoadedAllOldestReplies: Bool {
        replyPaginationState.hasLoadedAllPreviousMessages
    }
    
    /// A Boolean value that returns whether the newest replies have all been loaded or not.
    public var hasLoadedAllNewestReplies: Bool {
        replyPaginationState.hasLoadedAllNextMessages
    }

    /// A Boolean value that returns whether the channel is currently loading older replies.
    public var isLoadingOlderReplies: Bool {
        replyPaginationState.isLoadingPreviousMessages
    }

    /// A Boolean value that returns whether the channel is currently loading a page around a reply.
    public var isLoadingMiddleReplies: Bool {
        replyPaginationState.isLoadingMiddleMessages
    }

    /// A Boolean value that returns whether the channel is currently loading newer replies.
    public var isLoadingNewerReplies: Bool {
        replyPaginationState.isLoadingNextMessages
    }
}
