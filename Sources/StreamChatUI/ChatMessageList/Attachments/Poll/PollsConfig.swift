//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The configuration for the various poll features. It determines if the user can or can not enable certain poll features.
public struct PollsConfig: Sendable {
    /// Configuration for allowing multiple votes in a poll.
    public var multipleVotes: PollsEntryConfig
    /// Configuration for enabling anonymous polls.
    public var anonymousPoll: PollsEntryConfig
    /// Configuration for allowing users to suggest options in a poll.
    public var suggestAnOption: PollsEntryConfig
    /// Configuration for adding comments to a poll.
    public var addComments: PollsEntryConfig
    /// Configuration for setting the maximum number of votes per person.
    public var maxVotesPerPerson: PollsEntryConfig

    /// Initializes a new `PollsConfig` with the given configurations.
    ///
    /// - Parameters:
    ///   - multipleVotes: Configuration for allowing multiple votes. Defaults to `.default`.
    ///   - anonymousPoll: Configuration for enabling anonymous polls. Defaults to `.default`.
    ///   - suggestAnOption: Configuration for allowing users to suggest options. Defaults to `.default`.
    ///   - addComments: Configuration for adding comments. Defaults to `.default`.
    ///   - maxVotesPerPerson: Configuration for setting the maximum number of votes per person. Defaults to `.default`.
    public init(
        multipleVotes: PollsEntryConfig = PollsEntryConfig(),
        anonymousPoll: PollsEntryConfig = PollsEntryConfig(),
        suggestAnOption: PollsEntryConfig = PollsEntryConfig(),
        addComments: PollsEntryConfig = PollsEntryConfig(),
        maxVotesPerPerson: PollsEntryConfig = PollsEntryConfig()
    ) {
        self.multipleVotes = multipleVotes
        self.anonymousPoll = anonymousPoll
        self.suggestAnOption = suggestAnOption
        self.addComments = addComments
        self.maxVotesPerPerson = maxVotesPerPerson
    }
}

/// Config for individual poll entry.
public struct PollsEntryConfig: Sendable {
    /// Indicates whether the poll entry is configurable.
    public var configurable: Bool
    /// Indicates the default value of the poll entry.
    public var defaultValue: Bool

    public init() {
        configurable = true
        defaultValue = false
    }
    
    public init(configurable: Bool = true, defaultValue: Bool) {
        self.configurable = configurable
        self.defaultValue = defaultValue
    }
}

extension PollsEntryConfig {
    /// The default configuration for a poll entry. It will make it configurable but disabled by default.
    // TODO: Uncomment later
    public static var `default`: PollsEntryConfig { PollsEntryConfig(configurable: true, defaultValue: false) }
    /// The feature should not be supported, so it is not configurable by the user.
    public static let notConfigurable = PollsEntryConfig(configurable: false, defaultValue: false)
}
