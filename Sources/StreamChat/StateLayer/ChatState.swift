//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represent a ``ChatChannel`` and its state.
@available(iOS 13.0, *)
public final class ChatState: ObservableObject {
    private let cid: ChannelId
    private var channelObserver: EntityDatabaseObserverWrapper<ChatChannel, ChannelDTO>?
    private let paginationState: MessagesPaginationState
    
    init(cid: ChannelId, messageOrder: MessageOrdering, database: DatabaseContainer, paginationState: MessagesPaginationState) {
        self.cid = cid
        self.messageOrder = messageOrder
        self.paginationState = paginationState
        startObservingChannel(with: cid, in: database)
    }
    
    // MARK: - Represented Channel
    
    // TODO: Exposing it as non-nil? Requires one DB fetch on Chat creation
    @Published private(set) var channel: ChatChannel?
    
    // MARK: - Messages
    
    /// Describes the ordering of messages.
    public let messageOrder: MessageOrdering
    
    /// An array of loaded messages.
    ///
    /// Messages are ordered by timestamp and``messageOrder``.
    ///
    /// Use load messages in ``Chat`` for loading more messages.
    @Published public private(set) var messages: [ChatMessage] = []
    
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
    
    // MARK: - Mutating the State
    
    // Force mutations on main actor since ChatState is meant to be used by UI.
    @MainActor func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<ChatState, Value>) {
        self[keyPath: keyPath] = value
    }
    
    @MainActor func setMessages(_ messages: [ChatMessage]) {
        setValue(messages, for: \.messages)
    }
}

// MARK: Observing the channel

@available(iOS 13.0, *)
extension ChatState {
    private func startObservingChannel(with cid: ChannelId, in database: DatabaseContainer) {
        channelObserver = { [weak self] in
            let observer = EntityDatabaseObserverWrapper(
                isBackground: true,
                database: database,
                fetchRequest: ChannelDTO.fetchRequest(for: cid),
                itemCreator: { try $0.asModel() as ChatChannel }
            )
            .onChange { [weak self] change in
                self?.onChannelChange(change.item)
            }
            return observer
        }()
        do {
            try channelObserver?.startObserving()
        } catch {
            log.error("Failed to start the channel observer for \(cid)")
        }
    }
    
    private func onChannelChange(_ channel: ChatChannel) {
        Task { await setValue(channel, for: \.channel) }
    }
}
