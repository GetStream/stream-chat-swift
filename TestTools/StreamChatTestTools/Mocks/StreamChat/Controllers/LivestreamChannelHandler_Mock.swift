//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// A mock `LivestreamChannelHandling` implementation used to verify that the higher-level
/// `LivestreamChannelController` and `LivestreamChat` correctly forward configuration,
/// events and lifecycle calls to the handler. Handler-internal behaviour is exercised in
/// `LivestreamChannelHandler_Tests` so wrapper tests do not need to set up real handler
/// state.
final class LivestreamChannelHandler_Mock: LivestreamChannelHandling, @unchecked Sendable {
    // MARK: - Configuration

    var maxMessageLimitOptions: MaxMessageLimitOptions?
    var countSkippedMessagesWhenPaused: Bool = false
    var loadInitialMessagesFromCache: Bool = true
    var timerType: TimerScheduling.Type = DefaultTimer.self

    // MARK: - State

    var channelQuery: ChannelQuery
    var cid: ChannelId? { channelQuery.cid }
    var channel: ChatChannel?
    var messages: [ChatMessage] = []
    var isPaused: Bool = false
    var skippedMessagesAmount: Int = 0

    // MARK: - Pagination

    var hasLoadedAllPreviousMessages: Bool = false
    /// Matches the real handler default: `true` when no messages are loaded.
    var hasLoadedAllNextMessages: Bool = true
    var isLoadingPreviousMessages: Bool = false
    var isLoadingNextMessages: Bool = false
    var isLoadingMiddleMessages: Bool = false
    var isJumpingToMessage: Bool = false
    var oldestFetchedMessageId: MessageId?
    var newestFetchedMessageId: MessageId?

    // MARK: - Call Tracking

    @Atomic var populateFromCacheIfEnabled_callCount = 0

    @Atomic var handleChannelPayload_callCount = 0
    @Atomic var handleChannelPayload_payload: ChannelPayload?
    @Atomic var handleChannelPayload_channelQuery: ChannelQuery?

    @Atomic var handlePaginationFailure_callCount = 0
    @Atomic var handlePaginationFailure_channelQuery: ChannelQuery?
    @Atomic var handlePaginationFailure_error: Error?

    @Atomic var beginPagination_callCount = 0
    @Atomic var beginPagination_channelQuery: ChannelQuery?

    @Atomic var pause_callCount = 0
    @Atomic var resume_callCount = 0
    @Atomic var resetSkippedMessagesCountIfNeeded_callCount = 0
    @Atomic var clearMessages_callCount = 0

    @Atomic var didReceiveEvent_callCount = 0
    @Atomic var didReceiveEvent_event: Event?
    @Atomic var didReceiveEvent_allEvents: [Event] = []

    @Atomic var setHandlers_callCount = 0

    // MARK: - Stubs

    /// The value returned by `currentCooldownTime()`. Default is `0`.
    @Atomic var stubbedCurrentCooldownTime: Int = 0

    /// The captured `Handlers` struct. Use the `simulate*` helpers to invoke its closures
    /// from a test to verify forwarding by the wrapper.
    @Atomic var capturedHandlers: LivestreamChannelHandler.Handlers?

    // MARK: - Initialization

    init(channelQuery: ChannelQuery) {
        self.channelQuery = channelQuery
    }

    // MARK: - LivestreamChannelHandling

    func setHandlers(_ handlers: LivestreamChannelHandler.Handlers) {
        setHandlers_callCount += 1
        capturedHandlers = handlers
    }

    func populateFromCacheIfEnabled() {
        populateFromCacheIfEnabled_callCount += 1
    }

    func handleChannelPayload(_ payload: ChannelPayload, channelQuery: ChannelQuery) {
        handleChannelPayload_callCount += 1
        handleChannelPayload_payload = payload
        handleChannelPayload_channelQuery = channelQuery
    }

    func handlePaginationFailure(channelQuery: ChannelQuery, error: Error) {
        handlePaginationFailure_callCount += 1
        handlePaginationFailure_channelQuery = channelQuery
        handlePaginationFailure_error = error
    }

    func beginPagination(for channelQuery: ChannelQuery) {
        beginPagination_callCount += 1
        beginPagination_channelQuery = channelQuery
    }

    func pause() {
        pause_callCount += 1
    }

    func resume() {
        resume_callCount += 1
    }

    func resetSkippedMessagesCountIfNeeded() {
        resetSkippedMessagesCountIfNeeded_callCount += 1
    }

    func clearMessages() {
        clearMessages_callCount += 1
        messages = []
    }

    func didReceiveEvent(_ event: Event) {
        didReceiveEvent_callCount += 1
        didReceiveEvent_event = event
        _didReceiveEvent_allEvents.mutate { $0.append(event) }
    }

    func currentCooldownTime() -> Int {
        stubbedCurrentCooldownTime
    }

    // MARK: - Reset

    func cleanUp() {
        populateFromCacheIfEnabled_callCount = 0
        handleChannelPayload_callCount = 0
        handleChannelPayload_payload = nil
        handleChannelPayload_channelQuery = nil
        handlePaginationFailure_callCount = 0
        handlePaginationFailure_channelQuery = nil
        handlePaginationFailure_error = nil
        beginPagination_callCount = 0
        beginPagination_channelQuery = nil
        pause_callCount = 0
        resume_callCount = 0
        resetSkippedMessagesCountIfNeeded_callCount = 0
        clearMessages_callCount = 0
        didReceiveEvent_callCount = 0
        didReceiveEvent_event = nil
        didReceiveEvent_allEvents = []
        setHandlers_callCount = 0
        stubbedCurrentCooldownTime = 0
    }

    // MARK: - Simulation Helpers

    /// Invokes the captured `channelDidChange` callback with the given channel.
    @MainActor
    func simulateChannelDidChange(_ channel: ChatChannel) {
        capturedHandlers?.channelDidChange(channel)
    }

    /// Invokes the captured `messagesDidChange` callback with the given messages.
    @MainActor
    func simulateMessagesDidChange(_ messages: [ChatMessage]) {
        capturedHandlers?.messagesDidChange(messages)
    }

    /// Invokes the captured `pauseDidChange` callback with the given value.
    @MainActor
    func simulatePauseDidChange(_ isPaused: Bool) {
        capturedHandlers?.pauseDidChange(isPaused)
    }

    /// Invokes the captured `skippedMessagesAmountDidChange` callback with the given value.
    @MainActor
    func simulateSkippedMessagesAmountDidChange(_ amount: Int) {
        capturedHandlers?.skippedMessagesAmountDidChange(amount)
    }

    /// Invokes the captured `typingUsersDidChange` callback with the given users.
    @MainActor
    func simulateTypingUsersDidChange(_ users: Set<ChatUser>) {
        capturedHandlers?.typingUsersDidChange(users)
    }
}
