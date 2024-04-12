//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a ``ChatMessage`` and its state.
@available(iOS 13.0, *)
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
        observer.start(
            with: .init(
                messageDidChange: { [weak self] message, changedReactions in
                    self?.message = message
                    if let changedReactions {
                        self?.reactions = changedReactions
                    }
                },
                repliesDidChange: { [weak self] in self?.replies = $0 }
            )
        )
        reactions = message.latestReactions.sorted(by: ChatMessageReaction.defaultSorting)
        replies = observer.repliesObserver.items
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
    /// Use ``Chat/loadReactions(of:pagination:)`` for loading more reaactions.
    @Published public private(set) var reactions = [ChatMessageReaction]()
    
    // MARK: - Replies
    
    /// An array of loaded replies sorted by ``MessageOrdering``.
    @Published public internal(set) var replies = StreamCollection<ChatMessage>([])
    
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
}

@available(iOS 13.0, *)
extension ChatMessageReaction {
    static func defaultSorting(_ first: ChatMessageReaction, _ second: ChatMessageReaction) -> Bool {
        first.updatedAt > second.updatedAt
    }
}
