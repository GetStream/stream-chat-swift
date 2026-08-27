//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A model describing a system message that can be sent alongside channel actions
/// such as adding members, removing members, or truncating a channel.
///
/// Unlike a regular message, a system message only carries its text and optional
/// extra data.
public struct SystemMessage: Equatable, Sendable {
    /// The text of the system message.
    public var text: String

    /// Additional data associated with the system message.
    public var extraData: [String: RawJSON]

    /// Creates a new system message.
    ///
    /// - Parameters:
    ///   - text: The text of the system message.
    ///   - extraData: Additional data associated with the system message. Empty by default.
    public init(text: String, extraData: [String: RawJSON] = [:]) {
        self.text = text
        self.extraData = extraData
    }
}
