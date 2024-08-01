//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The model for a Poll.
public struct Poll: Equatable {
    /// A boolean indicating whether the poll allows answers.
    public let allowAnswers: Bool
    
    /// A boolean indicating whether the poll allows user-suggested options.
    public let allowUserSuggestedOptions: Bool
    
    /// The count of answers received for the poll.
    public let answersCount: Int
    
    /// The date and time when the poll was created.
    public let createdAt: Date
    
    /// A brief description of the poll.
    /// This property is optional and may be `nil`.
    public let pollDescription: String?
    
    /// A boolean indicating whether the poll enforces unique votes.
    public let enforceUniqueVote: Bool
    
    /// The unique identifier of the poll.
    public let id: String
    
    /// The name of the poll.
    public let name: String
    
    /// The date and time when the poll was last updated.
    /// This property is optional and may be `nil`.
    public let updatedAt: Date?
    
    /// The count of votes received for the poll.
    public let voteCount: Int
    
    /// A dictionary containing custom fields associated with the poll.
    public let extraData: [String: RawJSON]
    
    /// A dictionary mapping option IDs to the count of votes each option has received.
    /// This property is optional and may be `nil`.
    public let voteCountsByOption: [String: Int]?
    
    /// A boolean indicating whether the poll is closed.
    public let isClosed: Bool
    
    /// The maximum number of votes allowed per user.
    /// This property is optional and may be `nil`.
    public let maxVotesAllowed: Int?
    
    /// Represents the visibility of the voting process.
    /// This property is optional and may be `nil`.
    public let votingVisibility: VotingVisibility?
    
    /// The user who created the poll.
    /// This property is optional and may be `nil`.
    public let createdBy: ChatUser?
    
    /// A list of the latest answers received for the poll.
    public let latestAnswers: [PollVote]
    
    /// An array of options available in the poll.
    public var options: [PollOption]
    
    /// A list of the latest votes received for each option in the poll.
    public let latestVotesByOption: [PollOption]

    /// The list of the current user votes.
    public let ownVotes: [PollVote]
}

/// Poll domain logic helpers.
public extension Poll {
    /// Returns the vote of the current user for the given option in case the user has voted.
    func currentUserVote(forOption option: PollOption) -> PollVote? {
        ownVotes.first(where: { $0.optionId == option.id })
    }

    /// Returns a Boolean value indicating whether the current user has voted the given option.
    func hasCurrentUserVoted(forOption option: PollOption) -> Bool {
        ownVotes.map(\.optionId).contains(option.id)
    }
}
