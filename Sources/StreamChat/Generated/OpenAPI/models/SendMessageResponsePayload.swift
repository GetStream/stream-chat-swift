//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendMessageResponsePayload: Sendable, Codable, JSONEncodable {
    /// Map of mentioned user ID to whether that user is currently an active channel member. Only set when include_mentioned_members was requested; omitted when the message has no mentions or the membership lookup failed
    let mentionedMembers: [String: Bool]?
    /// Represents any chat message
    let message: MessageResponse

    init(
        mentionedMembers: [String: Bool]? = nil,
        message: MessageResponse
    ) {
        self.mentionedMembers = mentionedMembers
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case mentionedMembers = "mentioned_members"
        case message
    }
}
