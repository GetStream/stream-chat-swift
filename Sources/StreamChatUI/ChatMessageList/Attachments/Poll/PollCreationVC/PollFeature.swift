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
    /// The maximum votes per person configuration. If `nil` it means the max votes feature is not supported.
    public var maxVotesConfig: MaximumVotesConfig?

    public init(name: String, isEnabled: Bool, maxVotesConfig: MaximumVotesConfig?) {
        self.name = name
        self.isEnabled = isEnabled
        self.maxVotesConfig = maxVotesConfig
    }
}

/// The maximum votes per person configuration.
public struct MaximumVotesConfig {
    /// A boolean indicating if maximum votes is enabled.
    public var isEnabled: Bool
    /// The value of the maximum votes per person in case there is any maximum.
    public var maxVotes: Int?

    public init(isEnabled: Bool, maxVotes: Int?) {
        self.isEnabled = isEnabled
        self.maxVotes = maxVotes
    }
}
