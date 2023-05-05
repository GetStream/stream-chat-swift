//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A component responsible for handling the messages pagination state.
protocol MessagesPaginationStateHandling {
    /// The current state of the messages pagination.
    var state: MessagesPaginationState { get }

    /// This function should be called before performing the pagination call.
    func start(pagination: MessagesPagination)
    /// This function should be called with the result of the pagination call.
    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], Error>)
}

/// A component responsible for handling the messages pagination state.
class MessagesPaginationStateHandler: MessagesPaginationStateHandling {
    var state: MessagesPaginationState = .initial

    func start(pagination: MessagesPagination) {
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
            state.hasLoadedAllPreviousMessages = false
            state.hasLoadedAllNextMessages = true
            state.isLoadingPreviousMessages = false
            state.isLoadingMiddleMessages = false
            state.isLoadingNextMessages = false
            state.oldestFetchedMessage = nil
            state.newestFetchedMessage = nil
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

        case .around:
            state.oldestFetchedMessage = oldestFetchedMessage
            state.newestFetchedMessage = newestFetchedMessage

            if messages.count < pagination.pageSize {
                state.hasLoadedAllNextMessages = true
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
