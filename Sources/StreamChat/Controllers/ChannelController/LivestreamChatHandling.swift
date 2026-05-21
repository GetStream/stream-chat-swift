//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The external contract used by ``LivestreamChannelController`` and ``LivestreamChat``
/// when collaborating with a livestream channel handler.
///
/// The protocol exposes a deliberately narrow surface: read-only access to the
/// in-memory state, read-write access to the configuration options, and the
/// lifecycle methods the wrappers need to call. Tests can substitute a mock
/// implementation without having to subclass the concrete
/// ``LivestreamChatHandler``, which keeps the concrete type `final` and its
/// stored state free from external mutation.
protocol LivestreamChatHandling: AnyObject, Sendable {
    // MARK: - Configuration

    /// Configuration for message limiting behaviour.
    var maxMessageLimitOptions: MaxMessageLimitOptions? { get set }

    /// Whether the controller should count skipped messages while paused.
    var countSkippedMessagesWhenPaused: Bool { get set }

    /// Whether the handler should populate initial messages from the local cache.
    var loadInitialMessagesFromCache: Bool { get set }

    /// The timer scheduler used for the typing cleanup timers.
    var timerType: TimerScheduling.Type { get set }

    // MARK: - State

    /// The channel query backing this handler.
    var channelQuery: ChannelQuery { get }

    /// The channel id this handler observes.
    var cid: ChannelId? { get }

    /// The channel the handler represents.
    var channel: ChatChannel? { get }

    /// The messages of the channel the handler represents.
    var messages: [ChatMessage] { get }

    /// Whether message processing is currently paused.
    var isPaused: Bool { get }

    /// The amount of messages that were skipped during the pause state.
    var skippedMessagesAmount: Int { get }

    // MARK: - Pagination

    /// Whether all previous (older) messages have been loaded.
    var hasLoadedAllPreviousMessages: Bool { get }

    /// Whether all next (newer) messages have been loaded.
    var hasLoadedAllNextMessages: Bool { get }

    /// Whether a previous (older) page is currently loading.
    var isLoadingPreviousMessages: Bool { get }

    /// Whether a next (newer) page is currently loading.
    var isLoadingNextMessages: Bool { get }

    /// Whether a page around a specific message is currently loading.
    var isLoadingMiddleMessages: Bool { get }

    /// Whether the handler is currently in a mid-page state.
    var isJumpingToMessage: Bool { get }

    /// The id of the oldest message fetched so far, if any.
    var oldestFetchedMessageId: MessageId? { get }

    /// The id of the newest message fetched so far, if any.
    var newestFetchedMessageId: MessageId? { get }

    // MARK: - Lifecycle

    /// Registers the closures that are invoked when state changes.
    func setHandlers(_ handlers: LivestreamChatHandler.Handlers)

    /// Loads the initial messages from the data store when enabled.
    func populateFromCacheIfEnabled()

    /// Applies the freshly-fetched channel payload to the in-memory state.
    func handleChannelPayload(_ payload: ChannelPayload, channelQuery: ChannelQuery)

    /// Marks pagination as failed without mutating in-memory data.
    func handlePaginationFailure(channelQuery: ChannelQuery, error: Error)

    /// Begins a pagination request for the given query.
    func beginPagination(for channelQuery: ChannelQuery)

    /// Pauses the collecting of new messages.
    func pause()

    /// Resumes the collecting of new messages.
    func resume()

    /// Resets only the skipped messages counter, leaving the pause state alone.
    func resetSkippedMessagesCountIfNeeded()

    /// Clears the messages array.
    func clearMessages()

    /// Routes an event to the appropriate handler.
    func didReceiveEvent(_ event: Event)

    /// Returns the current cooldown time for the channel, or `0` when slow
    /// mode is not active.
    func currentCooldownTime() -> Int
}
