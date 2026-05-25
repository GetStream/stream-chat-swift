//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents the observable state of a ``LivestreamChat`` instance.
///
/// ``LivestreamChatState`` mirrors the in-memory state managed by
/// ``LivestreamChatHandler`` and exposes it via `@Published` properties so it
/// can be observed from SwiftUI views or other Combine consumers.
@MainActor public final class LivestreamChatState: ObservableObject {
    private let handler: LivestreamChatHandling

    /// The client instance the ``LivestreamChat`` was created with.
    public let client: ChatClient

    init(handler: LivestreamChatHandling, client: ChatClient) {
        self.handler = handler
        self.client = client
        channel = handler.channel
        messages = handler.messages
        isPaused = handler.isPaused
        skippedMessagesAmount = handler.skippedMessagesAmount
        typingUsers = handler.channel?.currentlyTypingUsers ?? []
        configureHandlerCallbacks()
    }

    // MARK: - Represented Channel and Query

    /// The channel id of the represented channel.
    ///
    /// - Important: It is nil, if the channel is not locally available. Call ``LivestreamChat/get()`` for fetching the latest state.
    public var cid: ChannelId? { handler.cid }

    /// The channel query used for looking up the channel.
    public var channelQuery: ChannelQuery { handler.channelQuery }

    /// The represented ``ChatChannel``.
    ///
    /// - Important: It is nil if the channel is not locally available. Call ``LivestreamChat/get()`` for fetching the latest state.
    @Published public internal(set) var channel: ChatChannel?

    // MARK: - Messages

    /// An array of loaded messages.
    ///
    /// Messages are ordered top to bottom (newest first).
    @Published public internal(set) var messages: [ChatMessage] = []

    /// A Boolean value that returns whether the oldest messages have all been loaded or not.
    public var hasLoadedAllOldestMessages: Bool {
        handler.hasLoadedAllPreviousMessages
    }

    /// A Boolean value that returns whether the newest messages have all been loaded or not.
    public var hasLoadedAllNewestMessages: Bool {
        handler.hasLoadedAllNextMessages
    }

    /// A Boolean value that returns whether the channel is currently loading newer messages.
    public var isLoadingNewerMessages: Bool {
        handler.isLoadingNextMessages
    }

    /// A Boolean value that returns whether the channel is currently loading older messages.
    public var isLoadingOlderMessages: Bool {
        handler.isLoadingPreviousMessages
    }

    /// A Boolean value that returns whether the channel is currently loading a page around a message.
    public var isLoadingMiddleMessages: Bool {
        handler.isLoadingMiddleMessages
    }

    /// A Boolean value that returns whether the channel is currently in a mid-page.
    public var isJumpingToMessage: Bool {
        handler.isJumpingToMessage
    }

    // MARK: - Pause State

    /// A Boolean value that indicates whether message processing is paused.
    ///
    /// When paused, new messages from other users will not be added to
    /// ``messages``.
    @Published public internal(set) var isPaused: Bool = false

    /// The amount of messages that were skipped during the pause state.
    @Published public internal(set) var skippedMessagesAmount: Int = 0

    var isResuming: Bool = false

    // MARK: - Typing

    /// The current set of users typing in the channel (excludes thread typing events).
    @Published public internal(set) var typingUsers: Set<ChatUser> = []

    // MARK: - Throttling and Slow Mode

    /// The duration until the current user can't send new messages when the channel has slow mode enabled.
    ///
    /// - Returns: 0, if slow mode is not enabled or the channel can skip slow mode, otherwise the remaining cooldown duration in seconds.
    public var remainingCooldownDuration: Int {
        handler.currentCooldownTime()
    }
    
    // MARK: - Internal
    
    private func configureHandlerCallbacks() {
        handler.setHandlers(
            LivestreamChatHandler.Handlers(
                channelDidChange: { [weak self] channel in
                    self?.channel = channel
                },
                messagesDidChange: { [weak self] messages in
                    self?.messages = messages
                },
                pauseDidChange: { [weak self] isPaused in
                    self?.isPaused = isPaused
                },
                skippedMessagesAmountDidChange: { [weak self] skipped in
                    self?.skippedMessagesAmount = skipped
                },
                typingUsersDidChange: { [weak self] typingUsers in
                    self?.typingUsers = typingUsers
                }
            )
        )
    }
}
