//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message the person sent that is not in the conversation yet, such as while its
/// conversation opens or its attachments upload.
///
/// ``AIConversationView`` shows it as theirs straight away. The first message of theirs that
/// arrives after it takes its place, keeping its attachments, and the list does not move.
public struct AIPendingMessage: Identifiable, Sendable {
    public let id: String
    public var text: String
    public var attachments: [AIMessageAttachment]

    /// - Parameters:
    ///   - id: The message's id once it arrives, when you know it. Its copy is then found by it
    ///     rather than by where it lands.
    ///   - text: What the person wrote.
    ///   - attachments: What they sent with it, such as the photos and files they picked.
    public init(id: String = UUID().uuidString, text: String, attachments: [AIMessageAttachment] = []) {
        self.id = id
        self.text = text
        self.attachments = attachments
    }
}
