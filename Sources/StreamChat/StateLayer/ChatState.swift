//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a ``ChatChannel`` and its state.
@available(iOS 13.0, *)
public final class ChatState: ObservableObject {
    private let cid: ChannelId
    private var channelObserver: EntityDatabaseObserverWrapper<ChatChannel, ChannelDTO>?
    private let paginationState: MessagesPaginationState
    private let observer: Observer
    
    init(cid: ChannelId, channelQuery: ChannelQuery, messageOrder: MessageOrdering, database: DatabaseContainer, eventNotificationCenter: EventNotificationCenter, paginationState: MessagesPaginationState) {
        self.cid = cid
        self.messageOrder = messageOrder
        self.paginationState = paginationState
        observer = Observer(cid: cid, channelQuery: channelQuery, messageOrder: messageOrder, database: database, eventNotificationCenter: eventNotificationCenter)
        
        observer.start(
            with: .init(
                channelDidChange: { [weak self] in await self?.setValue($0, for: \.channel) },
                messagesDidChange: { [weak self] in await self?.setValue($0, for: \.messages) },
                typingUsersDidChange: { [weak self] in await self?.setValue($0, for: \.typingUsers) },
                watchersDidChange: { [weak self] in await self?.setValue($0, for: \.watchers) }
            )
        )
    }
    
    // MARK: - Represented Channel
    
    /// The represented ``ChatChannel``.
    @Published public private(set) var channel: ChatChannel?
    
    // MARK: - Messages
    
    /// Describes the ordering of messages.
    public let messageOrder: MessageOrdering
    
    /// An array of loaded messages.
    ///
    /// Messages are ordered by timestamp and``messageOrder`` (In case of ``MessageOrdering.bottomToTop`` the list is sorted in ascending order).
    ///
    /// Use load messages in ``Chat`` for loading more messages.
    @Published public private(set) var messages = StreamCollection<ChatMessage>([])
    
    /// A Boolean value that returns whether the oldest messages have all been loaded or not.
    public var hasLoadedAllPreviousMessages: Bool {
        paginationState.hasLoadedAllPreviousMessages
    }
    
    /// A Boolean value that returns whether the newest messages have all been loaded or not.
    public var hasLoadedAllNextMessages: Bool {
        paginationState.hasLoadedAllNextMessages || messages.isEmpty
    }

    /// A Boolean value that returns whether the channel is currently in a mid-page.
    /// The value is false if the channel has the first page loaded.
    /// The value is true if the channel is in a mid fragment and didn't load the first page yet.
    public var isJumpingToMessage: Bool {
        paginationState.isJumpingToMessage
    }

    /// A Boolean value that returns whether the channel is currently loading a page around a message.
    public var isLoadingMiddleMessages: Bool {
        paginationState.isLoadingMiddleMessages
    }

    /// A Boolean value that returns whether the channel is currently loading next (new) messages.
    public var isLoadingNextMessages: Bool {
        paginationState.isLoadingNextMessages
    }

    /// A Boolean value that returns whether the channel is currently loading previous (old) messages.
    public var isLoadingPreviousMessages: Bool {
        paginationState.isLoadingPreviousMessages
    }

    // MARK: - Throttling and Slow Mode
    
    /// The duration until the current user can't send new messages when the channel has slow mode enabled.
    ///
    /// - SeeAlso: ``Chat.enableSlowMode(cooldownDuration:)``
    /// - Returns: 0, if slow mode is not enabled, otherwise the remining cooldown duration in seconds.
    public var remainingCooldownDuration: Int {
        guard let channel else { return 0 }
        guard channel.cooldownDuration > 0 else { return 0 }
        guard !channel.ownCapabilities.contains(.skipSlowMode) else { return 0 }
        guard let lastMessageTimestamp = channel.lastMessageFromCurrentUser?.createdAt else { return 0 }
        let currentTime = Date().timeIntervalSince(lastMessageTimestamp)
        return max(0, channel.cooldownDuration - Int(currentTime))
    }
    
    // MARK: - Typing Users
    
    /// A list of users who are currently typing.
    @Published public private(set) var typingUsers = Set<ChatUser>()
    
    // MARK: - Watchers
    
    /// An array of users who are currently watching the channel.
    ///
    /// Use load watchers method in ``Chat`` for populating this array.
    @Published public private(set) var watchers = StreamCollection<ChatUser>([])
    
    // MARK: - Mutating the State
    
    // Force main actor when accessing the state.
    @MainActor func value<Value>(forKeyPath keyPath: KeyPath<ChatState, Value>) -> Value {
        self[keyPath: keyPath]
    }
    
    // Force mutations on main actor since ChatState is meant to be used by UI.
    @MainActor func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<ChatState, Value>) {
        self[keyPath: keyPath] = value
    }
}
