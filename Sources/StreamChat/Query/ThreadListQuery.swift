//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query to fetch the list of threads the current belongs to.
public struct ThreadListQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case watch
        case replyLimit = "reply_limit"
        case participantLimit = "participant_limit"
        case limit
        case next
    }

    /// A boolean indicating whether to watch for changes in the thread or not.
    public var watch: Bool
    /// The amount of replies fetched per thread. Default is 2.
    public var replyLimit: Int = 2
    /// The amount of participants fetched per thread. Default is 100.
    public var participantLimit: Int = 100
    /// The amount of threads fetched per page. Default is 10.
    public var limit: Int = 10
    /// The pagination token from the previous response to fetch the next page.
    public var next: String?

    public init(
        watch: Bool
    ) {
        self.watch = watch
    }
}
