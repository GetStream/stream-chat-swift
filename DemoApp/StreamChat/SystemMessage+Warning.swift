//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat

/// Demo App only feature to manually QA extra data in system messages.
///
/// A warning system message is a regular system message that carries a `warning`
/// flag in its extra data. Such messages are rendered in yellow, between two
/// warning emojis, by `DemoChatMessageContentView`.
extension SystemMessage {
    /// The extra data key used to flag a system message as a warning.
    static let warningExtraDataKey = "warning"

    /// Creates a warning system message with the given text.
    static func warning(text: String) -> SystemMessage {
        SystemMessage(text: text, extraData: [warningExtraDataKey: .bool(true)])
    }
}

extension ChatMessage {
    /// Whether this system message was flagged as a warning via its extra data.
    var isWarningSystemMessage: Bool {
        type == .system && extraData[SystemMessage.warningExtraDataKey]?.boolValue == true
    }
}
