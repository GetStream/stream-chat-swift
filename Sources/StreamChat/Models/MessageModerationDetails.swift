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
