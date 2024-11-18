//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes the details of a message which was moderated.
public struct MessageModerationDetails {
    /// The original message text.
    public let originalText: String
    /// The type of moderation performed to a message.
    public let action: MessageModerationAction
    /// Array of harm labels found in text.
    public let textHarms: [String]?
    /// Array of harm labels found in images.
    public let imageHarms: [String]?
    /// Blocklist name that was matched.
    public let blocklistMatched: String?
    /// Semantic filter phrase that was matched.
    public let semanticFilterMatched: String?
    /// A boolean value indicating if the message triggered the platform circumvention model.
    public let platformCircumvented: Bool?
}

/// The type of moderation performed to a message.
public struct MessageModerationAction: Equatable {
    let rawValue: String

    internal init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The message was bounced message, which means it needs to be rephrased and sent again.
    public static let bounce = Self(rawValue: "bounce")
    /// The message was blocked and removed from the chat.
    public static let remove = Self(rawValue: "remove")
}
