//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A component responsible for handling the messages pagination state.
protocol MessagesPaginationStateHandling {
    /// The current state of the messages pagination.
    var state: MessagesPaginationState { get }

    /// A method that will be called to inform the object that a pagination call is about to begin.
    func begin(pagination: MessagesPagination)
    /// A method that will be called to inform the object that a pagination call has finished
    /// with the provided result.
    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], Error>)
}

/// A component responsible for handling the messages pagination state.
class MessagesPaginationStateHandler: MessagesPaginationStateHandling {
    private let queue = DispatchQueue(label: "io.getstream.messages-pagination-state-handler")
    private var _state: MessagesPaginationState = .initial

    var state: MessagesPaginationState {
        get {
            queue.sync {
                _state
            }
        }
        set {
            queue.sync {
                _state = newValue
            }
        }
    }

    func begin(pagination: MessagesPagination) {
        // When loading a page around a message it means we jumped to a mid-page,
        // so now the newest page is not loaded.
        if pagination.parameter?.isJumpingToMessage == true {
            state.hasLoadedAllNextMessages = false
        }

        switch pagination.parameter {
        case .lessThan, .lessThanOrEqual:
            state.isLoadingPreviousMessages = true

        case .greaterThan, .greaterThanOrEqual:
            state.isLoadingNextMessages = true

        case .around:
            state.isLoadingMiddleMessages = true

        case .none:
            state = .initial
        }
    }

    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], Error>) {
        state.isLoadingNextMessages = false
        state.isLoadingMiddleMessages = false
        state.isLoadingPreviousMessages = false

        guard let messages = result.value else {
            return
        }

        let oldestFetchedMessage = messages.first
        let newestFetchedMessage = messages.last

        switch pagination.parameter {
        case .lessThan, .lessThanOrEqual:
            state.oldestFetchedMessage = oldestFetchedMessage
            if messages.count < pagination.pageSize {
                state.hasLoadedAllPreviousMessages = true
            }

        case .greaterThan, .greaterThanOrEqual:
            state.newestFetchedMessage = newestFetchedMessage
            if messages.count < pagination.pageSize {
                state.hasLoadedAllNextMessages = true
            }

        case let .around(messageId):
            state.oldestFetchedMessage = oldestFetchedMessage
            state.newestFetchedMessage = newestFetchedMessage

            calculateHasLoadedAllMessagesBasedOnTheLocation(of: messageId, given: messages)

            if messages.count < pagination.pageSize {
                state.hasLoadedAllNextMessages = true
                state.hasLoadedAllPreviousMessages = true
            }

        case .none:
            state.oldestFetchedMessage = oldestFetchedMessage
            state.hasLoadedAllNextMessages = true
            if messages.count < pagination.pageSize {
                state.hasLoadedAllPreviousMessages = true
            }
        }
    }

    /// If we are jumping to a message we can determine if we loaded the oldest page
    /// or the newest page, depending on where the aroundMessageId is located.
    /// - If the aroundMessageId is in the middle of the messages response,
    ///   it means there are still older and newer pages to fetch.
    /// - If the aroundMessageId is on first half of the messages response,
    ///   it means we loaded all the oldest pages
    /// - If the aroundMessageId is on the second half of the messages response,
    ///   it means we loaded all the newest pages
    /// - If the aroundMessageId is not in the messages response,
    ///   it means we jumping to a parent message inside a thread
    ///
    ///   **Note:** If we had the `newestMessageId` or `oldestMessageId` in a Channel/Thread
    ///   from the backend, this logic wouldn't be required. But until then we need to do this.
    private func calculateHasLoadedAllMessagesBasedOnTheLocation(
        of aroundMessageId: MessageId,
        given messages: [MessagePayload]
    ) {
        guard !messages.isEmpty else {
            return
        }

        let midIndex: Double = Double(messages.count) / 2.0
        let midPoint: Int = Int(round(midIndex)) - 1
        let secondHalf = messages[midPoint...].dropFirst() // drop the midpoint from second half

        if messages[midPoint].id == aroundMessageId {
            state.hasLoadedAllNextMessages = false
            state.hasLoadedAllPreviousMessages = false
        } else if secondHalf.contains(where: { $0.id == aroundMessageId }) {
            state.hasLoadedAllNextMessages = true
        } else {
            state.hasLoadedAllPreviousMessages = true
        }
    }
}
