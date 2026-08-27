//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// The model for a poll. `Poll` is an immutable snapshot of a poll entity at the given time.
public final class Poll: Identifiable, Sendable {
    /// A boolean indicating whether the poll allows answers/comments.
    public let allowAnswers: Bool

    /// A boolean indicating whether the poll allows user-suggested options.
    public let allowUserSuggestedOptions: Bool

    /// The count of answers/comments received for the poll.
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

    /// A list of the latest answers/comments received for the poll.
    public let latestAnswers: [PollVote]

    /// An array of options available in the poll.
    public let options: [PollOption]

    /// A list of the latest votes received for each option in the poll.
    public let latestVotesByOption: [PollOption]

    /// The list of the latest votes in the poll.
    public let latestVotes: [PollVote]

    /// The list of the current user votes.
    public let ownVotes: [PollVote]

    init(
        allowAnswers: Bool,
        allowUserSuggestedOptions: Bool,
        answersCount: Int,
        createdAt: Date,
        pollDescription: String?,
        enforceUniqueVote: Bool,
        id: String,
        name: String,
        updatedAt: Date?,
        voteCount: Int,
        extraData: [String: RawJSON],
        voteCountsByOption: [String: Int]?,
        isClosed: Bool,
        maxVotesAllowed: Int?,
        votingVisibility: VotingVisibility?,
        createdBy: ChatUser?,
        latestAnswers: [PollVote],
        options: [PollOption],
        latestVotesByOption: [PollOption],
        latestVotes: [PollVote],
        ownVotes: [PollVote]
    ) {
        self.allowAnswers = allowAnswers
        self.allowUserSuggestedOptions = allowUserSuggestedOptions
        self.answersCount = answersCount
        self.createdAt = createdAt
        self.pollDescription = pollDescription
        self.enforceUniqueVote = enforceUniqueVote
        self.id = id
        self.name = name
        self.updatedAt = updatedAt
        self.voteCount = voteCount
        self.extraData = extraData
        self.voteCountsByOption = voteCountsByOption
        self.isClosed = isClosed
        self.maxVotesAllowed = maxVotesAllowed
        self.votingVisibility = votingVisibility
        self.createdBy = createdBy
        self.latestAnswers = latestAnswers
        self.options = options
        self.latestVotesByOption = latestVotesByOption
        self.latestVotes = latestVotes
        self.ownVotes = ownVotes
    }
}

extension Poll: Equatable {
    public static func == (lhs: Poll, rhs: Poll) -> Bool {
        lhs.allowAnswers == rhs.allowAnswers &&
            lhs.allowUserSuggestedOptions == rhs.allowUserSuggestedOptions &&
            lhs.answersCount == rhs.answersCount &&
            lhs.createdAt == rhs.createdAt &&
            lhs.pollDescription == rhs.pollDescription &&
            lhs.enforceUniqueVote == rhs.enforceUniqueVote &&
            lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.voteCount == rhs.voteCount &&
            lhs.extraData == rhs.extraData &&
            lhs.voteCountsByOption == rhs.voteCountsByOption &&
            lhs.isClosed == rhs.isClosed &&
            lhs.maxVotesAllowed == rhs.maxVotesAllowed &&
            lhs.votingVisibility == rhs.votingVisibility &&
            lhs.createdBy == rhs.createdBy &&
            lhs.latestAnswers == rhs.latestAnswers &&
            lhs.options == rhs.options &&
            lhs.latestVotesByOption == rhs.latestVotesByOption &&
            lhs.latestVotes == rhs.latestVotes &&
            lhs.ownVotes == rhs.ownVotes
    }
}

/// Poll domain logic helpers.
public extension Poll {
    /// The value of the option with the most votes.
    var currentMaximumVoteCount: Int {
        voteCountsByOption?.values.max() ?? 0
    }

    /// Whether the poll is already closed and the provided option is the one, and **the only one** with the most votes.
    func isOptionWinner(_ option: PollOption) -> Bool {
        isClosed && isOptionWithMostVotes(option)
    }

    /// Whether the poll is already close and the provided option is one of that has the most votes.
    func isOptionOneOfTheWinners(_ option: PollOption) -> Bool {
        isClosed && isOptionWithMaximumVotes(option)
    }

    /// Whether the provided option is the one, and **the only one** with the most votes.
    func isOptionWithMostVotes(_ option: PollOption) -> Bool {
        let optionsWithMostVotes = voteCountsByOption?.filter { $0.value == currentMaximumVoteCount }
        return optionsWithMostVotes?.count == 1 && optionsWithMostVotes?[option.id] != nil
    }

    /// Whether the provided option is one of that has the most votes.
    func isOptionWithMaximumVotes(_ option: PollOption) -> Bool {
        let optionsWithMostVotes = voteCountsByOption?.filter { $0.value == currentMaximumVoteCount }
        return optionsWithMostVotes?[option.id] != nil
    }

    /// The vote count for the given option.
    func voteCount(for option: PollOption) -> Int {
        voteCountsByOption?[option.id] ?? 0
    }

    // The ratio of the votes for the given option in comparison with the number of total votes.
    func voteRatio(for option: PollOption) -> Float {
        if currentMaximumVoteCount == 0 {
            return 0
        }

        let optionVoteCount = voteCount(for: option)
        return Float(optionVoteCount) / Float(currentMaximumVoteCount)
    }

    /// Returns the vote of the current user for the given option in case the user has voted.
    func currentUserVote(for option: PollOption) -> PollVote? {
        ownVotes.first(where: { $0.optionId == option.id })
    }

    /// Returns a Boolean value indicating whether the current user has voted the given option.
    func hasCurrentUserVoted(for option: PollOption) -> Bool {
        ownVotes.contains(where: { $0.optionId == option.id })
    }
}
