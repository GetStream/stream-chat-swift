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
public struct MessageModerationAction: RawRepresentable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A bounced message means it needs to be rephrased and sent again.
    static let bounce = Self(rawValue: "MESSAGE_RESPONSE_ACTION_BOUNCE")
    /// A flagged message means it was sent for review in the dashboard but the message was still published.
    static let flag = Self(rawValue: "MESSAGE_RESPONSE_ACTION_FLAG")
    /// A blocked message means it was not published and it was sent for review in the dashboard.
    static let block = Self(rawValue: "MESSAGE_RESPONSE_ACTION_BLOCK")
}
