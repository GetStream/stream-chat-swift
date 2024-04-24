//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PollOption: Equatable {
    public let id: String
    public var text: String
    public var latestVotes: [PollVote]
    public var custom: [String: RawJSON]?
    
    public init(
        id: String = UUID().uuidString,
        text: String,
        latestVotes: [PollVote] = [],
        custom: [String: RawJSON]? = nil
    ) {
        self.id = id
        self.text = text
        self.latestVotes = latestVotes
        self.custom = custom
    }
}
