//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Poll: Equatable {
    public let allowAnswers: Bool
    public let allowUserSuggestedOptions: Bool
    public let answersCount: Int
    public let createdAt: Date
    public let pollDescription: String?
    public let enforceUniqueVote: Bool
    public let id: String
    public let name: String
    public let updatedAt: Date?
    public let voteCount: Int
    public let custom: [String: RawJSON]
    public let voteCountsByOption: [String: Int]?
    public let isClosed: Bool
    public let maxVotesAllowed: Int?
    public let votingVisibility: String?
    public let createdBy: ChatUser?
    public let latestAnswers: [PollVote]
    public var options: [PollOption]
    public let latestVotesByOption: [PollOption]
}
