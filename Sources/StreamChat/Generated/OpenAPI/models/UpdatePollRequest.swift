//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdatePollRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum UpdatePollRequestVotingVisibility: String, Sendable, Codable, CaseIterable {
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

    /// Allow answers
    var allowAnswers: Bool?
    /// Allow user suggested options
    var allowUserSuggestedOptions: Bool?
    var custom: [String: RawJSON]?
    /// Poll description
    var description: String?
    /// Enforce unique vote
    var enforceUniqueVote: Bool?
    /// Poll ID
    var id: String
    /// Is closed
    var isClosed: Bool?
    /// Max votes allowed
    var maxVotesAllowed: Int?
    /// Poll name
    var name: String
    /// Poll options
    var options: [PollOptionRequest]?
    /// Voting visibility
    var votingVisibility: UpdatePollRequestVotingVisibility?

    init(allowAnswers: Bool? = nil, allowUserSuggestedOptions: Bool? = nil, custom: [String: RawJSON]? = nil, description: String? = nil, enforceUniqueVote: Bool? = nil, id: String, isClosed: Bool? = nil, maxVotesAllowed: Int? = nil, name: String, options: [PollOptionRequest]? = nil, votingVisibility: UpdatePollRequestVotingVisibility? = nil) {
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
        case custom = "Custom"
        case description
        case enforceUniqueVote = "enforce_unique_vote"
        case id
        case isClosed = "is_closed"
        case maxVotesAllowed = "max_votes_allowed"
        case name
        case options
        case votingVisibility = "voting_visibility"
    }

    static func == (lhs: UpdatePollRequest, rhs: UpdatePollRequest) -> Bool {
        lhs.allowAnswers == rhs.allowAnswers &&
            lhs.allowUserSuggestedOptions == rhs.allowUserSuggestedOptions &&
            lhs.custom == rhs.custom &&
            lhs.description == rhs.description &&
            lhs.enforceUniqueVote == rhs.enforceUniqueVote &&
            lhs.id == rhs.id &&
            lhs.isClosed == rhs.isClosed &&
            lhs.maxVotesAllowed == rhs.maxVotesAllowed &&
            lhs.name == rhs.name &&
            lhs.options == rhs.options &&
            lhs.votingVisibility == rhs.votingVisibility
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(allowAnswers)
        hasher.combine(allowUserSuggestedOptions)
        hasher.combine(custom)
        hasher.combine(description)
        hasher.combine(enforceUniqueVote)
        hasher.combine(id)
        hasher.combine(isClosed)
        hasher.combine(maxVotesAllowed)
        hasher.combine(name)
        hasher.combine(options)
        hasher.combine(votingVisibility)
    }
}
