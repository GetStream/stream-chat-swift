//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMessageResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var message: MessageResponse
    var pendingMessageMetadata: [String: String]?

    init(duration: String, message: MessageResponse, pendingMessageMetadata: [String: String]? = nil) {
        self.duration = duration
        self.message = message
        self.pendingMessageMetadata = pendingMessageMetadata
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case message
        case pendingMessageMetadata = "pending_message_metadata"
    }

    static func == (lhs: UpdateMessageResponse, rhs: UpdateMessageResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.message == rhs.message &&
            lhs.pendingMessageMetadata == rhs.pendingMessageMetadata
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(message)
        hasher.combine(pendingMessageMetadata)
    }
}
