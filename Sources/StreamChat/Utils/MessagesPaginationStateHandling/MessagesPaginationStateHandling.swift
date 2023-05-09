//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    private let parentMessageId: MessageId?

    init(parentMessageId: MessageId?) {
        self.parentMessageId = parentMessageId
    }

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
                state.newestFetchedMessage = nil
                state.hasLoadedAllNextMessages = true
            }

        case let .around(replyId):
            state.oldestFetchedMessage = oldestFetchedMessage
            state.newestFetchedMessage = newestFetchedMessage

            if messages.count < pagination.pageSize {
                state.hasLoadedAllNextMessages = true
                state.hasLoadedAllPreviousMessages = true
            }

            if parentMessageId == replyId {
                state.hasLoadedAllPreviousMessages = true
            }

        case .none:
            state.oldestFetchedMessage = oldestFetchedMessage
            state.newestFetchedMessage = nil
            if messages.count < pagination.pageSize {
                state.hasLoadedAllNextMessages = true
            }
        }
    }
}
