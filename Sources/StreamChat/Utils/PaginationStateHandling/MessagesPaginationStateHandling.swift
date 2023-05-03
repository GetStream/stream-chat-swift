//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct MessagesPaginationState {
    var oldestFetchedMessage: MessagePayload?
    var newestFetchedMessage: MessagePayload?

    var oldestMessageAt: Date?
    var newestMessageAt: Date?

    var isJumpingToMessage: Bool

    var hasLoadedAllPreviousMessages: Bool

    var isLoadingNextMessages: Bool
    var isLoadingPreviousMessages: Bool
    var isLoadingMiddleMessages: Bool

    var isLoadingMessages: Bool {
        isLoadingNextMessages || isLoadingPreviousMessages || isLoadingMiddleMessages
    }

    static var initial: Self = .init(
        oldestFetchedMessage: nil,
        newestFetchedMessage: nil,
        oldestMessageAt: nil,
        newestMessageAt: nil,
        isJumpingToMessage: false,
        hasLoadedAllPreviousMessages: false,
        isLoadingNextMessages: false,
        isLoadingPreviousMessages: false,
        isLoadingMiddleMessages: false
    )
}

protocol MessagesPaginationStateHandling {
    var state: MessagesPaginationState { get }

    func start(pagination: MessagesPagination)
    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], Error>)
}

class PaginationStateHandler: MessagesPaginationStateHandling {
    var state: MessagesPaginationState = .initial

    func start(pagination: MessagesPagination) {
        if pagination.parameter?.isJumpingToMessage == true {
            state.isJumpingToMessage = true
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
            state.isLoadingPreviousMessages = false
            state.isLoadingMiddleMessages = false
            state.isLoadingNextMessages = false
            state.oldestFetchedMessage = nil
            state.newestFetchedMessage = nil
            state.isJumpingToMessage = false
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
        let oldestMessageAt = oldestFetchedMessage?.createdAt
        let newestMessageAt = newestFetchedMessage?.createdAt

        switch pagination.parameter {
        case .lessThan, .lessThanOrEqual:
            state.oldestMessageAt = oldestMessageAt
            state.oldestFetchedMessage = oldestFetchedMessage
            if messages.count < pagination.pageSize {
                state.hasLoadedAllPreviousMessages = true
            }

        case .greaterThan, .greaterThanOrEqual:
            state.newestMessageAt = newestMessageAt
            state.newestFetchedMessage = newestFetchedMessage
            if messages.count < pagination.pageSize {
                state.newestMessageAt = nil
                state.isJumpingToMessage = false
            }

        case .around:
            state.oldestMessageAt = oldestMessageAt
            state.newestMessageAt = newestMessageAt
            state.oldestFetchedMessage = oldestFetchedMessage
            state.newestFetchedMessage = newestFetchedMessage

        case .none:
            state.oldestMessageAt = oldestMessageAt
            state.oldestFetchedMessage = oldestFetchedMessage
            state.newestFetchedMessage = nil
            state.newestMessageAt = nil

            if messages.count < pagination.pageSize {
                state.isJumpingToMessage = false
                state.hasLoadedAllPreviousMessages = true
            }
        }

        if let aroundMessageId = pagination.parameter?.aroundMessageId, !messages.isEmpty {
            let midIndex = messages.count / 2
            let midPoint: Int = Int(floor(Double(midIndex)))
            let secondHalf = messages[midPoint...].dropFirst()

            // If the message is in the mid point, it means there's more pages to load in both sides
            if messages[midPoint].id == aroundMessageId {
                state.isJumpingToMessage = true
                // If the message is in the second half of the response, it means there are no more next messages,
                // so it means jumping is finished.
            } else if secondHalf.contains(where: { $0.id == aroundMessageId }) {
                state.isJumpingToMessage = false
                // Otherwise, if the message is on the first half, it means it loaded all previous messages.
                // If the messages was not found, it could also mean we are jumping to a parent message.
            } else {
                state.hasLoadedAllPreviousMessages = true
            }

            if messages.count < pagination.pageSize {
                state.isJumpingToMessage = false
                state.hasLoadedAllPreviousMessages = true
            }
        }
    }
}

class PaginationStateHandlerThreadDecorator: MessagesPaginationStateHandling {
    let queue = DispatchQueue(label: "io.getstream.messages-pagination-state-handler")
    let decoratee: MessagesPaginationStateHandling

    init(decoratee: MessagesPaginationStateHandling) {
        self.decoratee = decoratee
    }

    var state: MessagesPaginationState {
        queue.sync {
            self.decoratee.state
        }
    }

    func start(pagination: MessagesPagination) {
        queue.sync {
            self.decoratee.start(pagination: pagination)
        }
    }

    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], Error>) {
        queue.sync {
            self.decoratee.end(pagination: pagination, with: result)
        }
    }
}
