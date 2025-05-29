//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Erase type for structs which recursively contain themselves.
///
/// Example:
/// ```swift
/// struct ChatMessage {
///   let quotedMessage: ChatMessage?
/// }
/// ```
/// Can be written as:
/// ```swift
/// struct ChatMessage {
///   let quotedMessage: ChatMessage? { _quotedMessage.value as? ChatMessage }
///   let _quotedMessage: BoxedAny?
/// }
/// ```
struct BoxedAny {
    init?(_ value: (any Sendable)?) {
        guard value != nil else { return nil }
        self.value = value
    }

    let value: any Sendable
}
