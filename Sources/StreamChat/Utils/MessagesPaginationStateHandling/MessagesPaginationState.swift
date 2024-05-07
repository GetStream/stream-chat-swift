//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The current state of the messages pagination.
package struct MessagesPaginationState {
    // MARK: State

    /// The oldest fetched message while paginating.
    package var oldestFetchedMessage: MessagePayload?
    /// The newest fetched message while paginating.
    package var newestFetchedMessage: MessagePayload?

    /// A Boolean value that returns whether the newest messages have all been loaded or not.
    /// If false, it means that the channel is currently in a mid-page.
    package var hasLoadedAllNextMessages: Bool {
        didSet {
            if hasLoadedAllNextMessages {
                newestFetchedMessage = nil
            }
        }
    }

    /// A Boolean value that returns whether the oldest messages have all been loaded or not.
    package var hasLoadedAllPreviousMessages: Bool

    /// A Boolean value that returns whether the channel is currently loading next (new) messages.
    package var isLoadingNextMessages: Bool
    /// A Boolean value that returns whether the channel is currently loading previous (old) messages.
    package var isLoadingPreviousMessages: Bool
    /// A Boolean value that returns whether the channel is currently loading a page around a message.
    package var isLoadingMiddleMessages: Bool

    // MARK: Computed Properties

    /// A Boolean value that returns whether the channel is currently loading messages on either previous, mid or next pages.
    package var isLoadingMessages: Bool {
        isLoadingNextMessages || isLoadingPreviousMessages || isLoadingMiddleMessages
    }

    /// A Boolean value that returns whether the channel is currently in a mid-page.
    package var isJumpingToMessage: Bool {
        !hasLoadedAllNextMessages
    }

    /// The oldest fetched message createdAt date while paginating.
    package var oldestMessageAt: Date? {
        oldestFetchedMessage?.createdAt
    }

    /// The newest fetched message createdAt date while paginating.
    package var newestMessageAt: Date? {
        newestFetchedMessage?.createdAt
    }

    // MARK: Initial State

    /// The initial state.
    static var initial: Self = .init(
        oldestFetchedMessage: nil,
        newestFetchedMessage: nil,
        hasLoadedAllNextMessages: true,
        hasLoadedAllPreviousMessages: false,
        isLoadingNextMessages: false,
        isLoadingPreviousMessages: false,
        isLoadingMiddleMessages: false
    )
}
