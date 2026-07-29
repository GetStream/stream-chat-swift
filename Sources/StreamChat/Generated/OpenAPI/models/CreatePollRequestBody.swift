//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreatePollRequestBody: Sendable, Codable, JSONEncodable {
    enum CreatePollRequestVotingVisibility: String, Sendable, Codable, CaseIterable {
        case `public`
        case anonymous
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    /// Indicates whether users can suggest user defined answers
    let allowAnswers: Bool?
    let allowUserSuggestedOptions: Bool?
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
    let votingVisibility: CreatePollRequestVotingVisibility?

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
        votingVisibility: CreatePollRequestVotingVisibility? = nil
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
