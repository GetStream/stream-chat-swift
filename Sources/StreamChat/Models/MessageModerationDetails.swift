//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes the details of a message which was moderated.
public struct MessageModerationDetails: Sendable {
    /// The original message text.
    public let originalText: String
    /// The type of moderation performed to a message.
    public let action: MessageModerationAction

    // MARK: - Internal for now since the Backend is still finalising the API.

    /// Array of harm labels found in text.
    internal let textHarms: [String]?
    /// Array of harm labels found in images.
    internal let imageHarms: [String]?
    /// Blocklist name that was matched.
    internal let blocklistMatched: String?
    /// Semantic filter phrase that was matched.
    internal let semanticFilterMatched: String?
    /// A boolean value indicating if the message triggered the platform circumvention model.
    internal let platformCircumvented: Bool?
}

/// The type of moderation performed to a message.
public struct MessageModerationAction: RawRepresentable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The message was bounced, which means it needs to be rephrased and sent again.
    public static let bounce = Self(rawValue: "bounce")
    /// The message was blocked and removed from the chat.
    public static let remove = Self(rawValue: "remove")
}
