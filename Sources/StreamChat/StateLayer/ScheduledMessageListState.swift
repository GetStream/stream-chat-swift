//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents the current user's list of scheduled messages matching to the specified query.
@MainActor public final class ScheduledMessageListState: ObservableObject {
    private let observer: Observer
    private(set) var nextCursor: String?

    init(query: ScheduledMessageListQuery, database: DatabaseContainer) {
        self.query = query
        observer = Observer(query: query, database: database)
        scheduledMessages = observer.start(
            with: .init(scheduledMessagesDidChange: { [weak self] in self?.scheduledMessages = $0 })
        )
    }

    /// The query specifying and filtering the list of scheduled messages.
    public let query: ScheduledMessageListQuery

    /// An array of scheduled messages for the specified ``ScheduledMessageListQuery``.
    ///
    /// Pending scheduled messages come first, then the failed ones, each sorted by the date they are sent.
    @Published public private(set) var scheduledMessages: [ScheduledMessage] = []

    /// A Boolean value that returns whether all the scheduled messages are loaded.
    @Published public private(set) var hasLoadedAllScheduledMessages = false

    func setNextCursor(_ cursor: String?) {
        nextCursor = cursor
        hasLoadedAllScheduledMessages = cursor == nil
    }
}
