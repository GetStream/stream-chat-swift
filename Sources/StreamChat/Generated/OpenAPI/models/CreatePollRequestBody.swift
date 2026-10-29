//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class VotingVisibility: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Votes are public and can be seen by everyone.
    public static let `public` = VotingVisibility(rawValue: "public")
    /// Votes are anonymous and cannot be attributed to individual users.
    public static let anonymous = VotingVisibility(rawValue: "anonymous")
}

/// Contains all information needed to create a new poll
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
    /// Indicates the maximum amount of votes a user can cast
    let maxVotesAllowed: Int?
    /// The name of the poll
    let name: String
    let options: [PollOptionRequestBody]?
    /// Represents the visibility of votes in a poll.
    let votingVisibility: VotingVisibility?

    init(
        allowAnswers: Bool? = nil,
        allowUserSuggestedOptions: Bool? = nil,
        custom: [String: RawJSON]? = nil,
        description: String? = nil,
        enforceUniqueVote: Bool? = nil,
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
        self.maxVotesAllowed = maxVotesAllowed
        self.name = name
        self.options = options
        self.votingVisibility = votingVisibility
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(allowAnswers, forKey: .allowAnswers)
        try container.encodeIfPresent(allowUserSuggestedOptions, forKey: .allowUserSuggestedOptions)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(enforceUniqueVote, forKey: .enforceUniqueVote)
        try container.encodeIfPresent(maxVotesAllowed, forKey: .maxVotesAllowed)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(votingVisibility, forKey: .votingVisibility)
    }
}
