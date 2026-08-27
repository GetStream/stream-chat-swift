//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class VotingVisibility: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let `public` = VotingVisibility(rawValue: "public")
    public static let anonymous = VotingVisibility(rawValue: "anonymous")
}

final class CreatePollRequestBody: Sendable, Encodable, JSONEncodable {
    /// Indicates whether users can suggest user defined answers
    let allowAnswers: Bool?
    let allowUserSuggestedOptions: Bool?
    /// Custom data for this object
    let custom: [String: RawJSON]?
    /// A description of the poll
    let description: String?
    /// Indicates whether users can cast multiple votes
    let enforceUniqueVote: Bool?
    let id: String?
    /// Indicates whether the poll is open for voting
    let isClosed: Bool?
    /// Indicates the maximum amount of votes a user can cast
    let maxVotesAllowed: Int?
    /// The name of the poll
    let name: String
    let options: [PollOptionRequestBody]?
    let votingVisibility: VotingVisibility?

    init(
        allowAnswers: Bool? = nil,
        allowUserSuggestedOptions: Bool? = nil,
        custom: [String: RawJSON]? = nil,
        description: String? = nil,
        enforceUniqueVote: Bool? = nil,
        id: String? = nil,
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        name: String,
        options: [PollOptionRequestBody]? = nil,
        votingVisibility: VotingVisibility? = nil
    ) {
        self.allowAnswers = allowAnswers
        self.allowUserSuggestedOptions = allowUserSuggestedOptions
        self.custom = custom
        self.description = description
        self.enforceUniqueVote = enforceUniqueVote
        self.id = id
        self.isClosed = isClosed
        self.maxVotesAllowed = maxVotesAllowed
        self.name = name
        self.options = options
        self.votingVisibility = votingVisibility
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case allowAnswers = "allow_answers"
        case allowUserSuggestedOptions = "allow_user_suggested_options"
        case custom
        case description
        case enforceUniqueVote = "enforce_unique_vote"
        case id
        case isClosed = "is_closed"
        case maxVotesAllowed = "max_votes_allowed"
        case name
        case options
        case votingVisibility = "voting_visibility"
    }
}
