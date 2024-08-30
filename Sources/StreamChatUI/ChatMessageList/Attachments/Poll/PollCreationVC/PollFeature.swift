//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol describing the requirements of a poll feature.
public protocol PollFeature {
    /// The name of the feature.
    var name: String { get }
    /// A boolean value indicating if the feature is enabled or not.
    var isEnabled: Bool { get set }
}

/// A basic poll feature, which by default just provides a name and if it is enabled.
public struct BasicPollFeature: PollFeature {
    /// The name of the feature.
    public var name: String
    /// A boolean value indicating if the feature is enabled or not.
    public var isEnabled: Bool

    public init(name: String, isEnabled: Bool) {
        self.name = name
        self.isEnabled = isEnabled
    }
}

/// Multiple votes feature which includes additional configuration.
public struct MultipleVotesPollFeature: PollFeature {
    /// The name of the feature.
    public var name: String
    /// A boolean value indicating if the feature is enabled or not.
    public var isEnabled: Bool
    /// The configuration of the multiple votes feature.
    public var config: MultipleVotesConfig

    public init(name: String, isEnabled: Bool, config: MultipleVotesConfig) {
        self.name = name
        self.isEnabled = isEnabled
        self.config = config
    }
}

/// The configuration of the multiple votes feature.
public struct MultipleVotesConfig {
    /// A boolean value indicating if multiple votes is possible.
    public var enabled: Bool
    /// A boolean value indicating if there is a maximum number of votes per user.
    public var maxVotes: Int?

    public init(enabled: Bool, maxVotes: Int? = nil) {
        self.enabled = enabled
        self.maxVotes = maxVotes
    }

    /// The multiple votes feature is disabled.
    public static var disabled = Self(enabled: false, maxVotes: nil)

    /// The multiple votes feature is enabled without maximum votes.
    public static var enabled = Self(enabled: true, maxVotes: nil)

    /// The multiple votes feature is enabled with maximum votes per user.
    public static func limited(maxVotes: Int) -> Self {
        .init(enabled: true, maxVotes: maxVotes)
    }
}
