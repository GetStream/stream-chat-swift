//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query to fetch the list of threads the current belongs to.
internal struct ThreadListQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case watch
        case replyLimit = "reply_limit"
        case participantLimit = "participant_limit"
        case limit
        case next
    }

    /// A boolean indicating whether to watch for changes in the thread or not.
    internal var watch: Bool
    /// The amount of replies fetched per thread. Default is 2.
    internal var replyLimit: Int = 2
    /// The amount of participants fetched per thread. Default is 100.
    internal var participantLimit: Int = 100
    /// The amount of threads fetched per page. Default is 10.
    internal var limit: Int = 10
    /// The pagination token from the previous response to fetch the next page.
    internal var next: String?

    internal init(
        watch: Bool
    ) {
        self.watch = watch
    }
}
