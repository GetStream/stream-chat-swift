//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The model for an option in a poll.
public struct PollOption: Equatable {
    /// The unique identifier of the poll option.
    public let id: String
    
    /// The text describing the poll option.
    public var text: String
    
    /// A list of the latest votes received for this poll option.
    public var latestVotes: [PollVote]
    
    /// A dictionary containing custom fields associated with the poll option.
    /// This property is optional and may be `nil`.
    public var extraData: [String: RawJSON]?
    
    /// Initializes a new instance of `PollOption`.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the poll option. Defaults to a new UUID string.
    ///   - text: The text describing the poll option.
    ///   - latestVotes: A list of the latest votes received for this poll option. Defaults to an empty array.
    ///   - custom: A dictionary containing custom fields associated with the poll option. Defaults to `nil`.
    public init(
        id: String = UUID().uuidString,
        text: String,
        latestVotes: [PollVote] = [],
        extraData: [String: RawJSON]? = nil
    ) {
        self.id = id
        self.text = text
        self.latestVotes = latestVotes
        self.extraData = extraData
    }
}
