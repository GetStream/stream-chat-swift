//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollResponseDataVotingVisibility: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let `public` = PollResponseDataVotingVisibility(rawValue: "public")
    static let anonymous = PollResponseDataVotingVisibility(rawValue: "anonymous")
}

final class PollPayload: Sendable, Decodable {
    let allowAnswers: Bool
    let allowUserSuggestedOptions: Bool
    let answersCount: Int
    let createdAt: Date
    /// User response object
    let createdBy: UserPayload?
    let createdById: String
    let custom: [String: RawJSON]
    let description: String
    let enforceUniqueVote: Bool
    let id: String
    let isClosed: Bool?
    let latestAnswers: [PollVotePayload]
    let latestVotesByOption: [String: [PollVotePayload]]
    let maxVotesAllowed: Int?
    let name: String
    let options: [PollOptionPayload]
    let ownVotes: [PollVotePayload]
    let updatedAt: Date
    let voteCount: Int
    let voteCountsByOption: [String: Int]
    /// Voting visibility of the poll
    let votingVisibility: PollResponseDataVotingVisibility

    init(
        allowAnswers: Bool,
        allowUserSuggestedOptions: Bool,
        answersCount: Int,
        createdAt: Date,
        createdBy: UserPayload? = nil,
        createdById: String,
        custom: [String: RawJSON],
        description: String,
        enforceUniqueVote: Bool,
        id: String,
        isClosed: Bool? = nil,
        latestAnswers: [PollVotePayload],
        latestVotesByOption: [String: [PollVotePayload]],
        maxVotesAllowed: Int? = nil,
        name: String,
        options: [PollOptionPayload],
        ownVotes: [PollVotePayload],
        updatedAt: Date,
        voteCount: Int,
        voteCountsByOption: [String: Int],
        votingVisibility: PollResponseDataVotingVisibility
    ) {
        self.allowAnswers = allowAnswers
        self.allowUserSuggestedOptions = allowUserSuggestedOptions
        self.answersCount = answersCount
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.createdById = createdById
        self.custom = custom
        self.description = description
        self.enforceUniqueVote = enforceUniqueVote
        self.id = id
        self.isClosed = isClosed
        self.latestAnswers = latestAnswers
        self.latestVotesByOption = latestVotesByOption
        self.maxVotesAllowed = maxVotesAllowed
        self.name = name
        self.options = options
        self.ownVotes = ownVotes
        self.updatedAt = updatedAt
        self.voteCount = voteCount
        self.voteCountsByOption = voteCountsByOption
        self.votingVisibility = votingVisibility
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.allowAnswers = try container.decode(Bool.self, forKey: .allowAnswers)
        self.allowUserSuggestedOptions = try container.decode(
            Bool.self,
            forKey: .allowUserSuggestedOptions
        )
        self.answersCount = try container.decode(Int.self, forKey: .answersCount)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.createdBy = try container.decodeIfPresent(UserPayload.self, forKey: .createdBy)
        self.createdById = try container.decode(String.self, forKey: .createdById)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.description = try container.decode(String.self, forKey: .description)
        self.enforceUniqueVote = try container.decode(Bool.self, forKey: .enforceUniqueVote)
        self.id = try container.decode(String.self, forKey: .id)
        self.isClosed = try container.decodeIfPresent(Bool.self, forKey: .isClosed)
        self.latestAnswers = try container.decode([PollVotePayload].self, forKey: .latestAnswers)
        self.latestVotesByOption = try container.decode(
            [String: [PollVotePayload]].self,
            forKey: .latestVotesByOption
        )
        self.maxVotesAllowed = try container.decodeIfPresent(Int.self, forKey: .maxVotesAllowed)
        self.name = try container.decode(String.self, forKey: .name)
        self.options = try container.decode([PollOptionPayload].self, forKey: .options)
        self.ownVotes = try container.decode([PollVotePayload].self, forKey: .ownVotes)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.voteCount = try container.decode(Int.self, forKey: .voteCount)
        self.voteCountsByOption = try container.decode(
            [String: Int].self,
            forKey: .voteCountsByOption
        )
        self.votingVisibility = try container.decode(
            PollResponseDataVotingVisibility.self,
            forKey: .votingVisibility
        )
    }
}
