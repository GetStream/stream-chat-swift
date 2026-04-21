//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetMessageResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var message: MessageWithChannelResponse
    var pendingMessageMetadata: [String: String]?

    init(duration: String, message: MessageWithChannelResponse, pendingMessageMetadata: [String: String]? = nil) {
        self.duration = duration
        self.message = message
        self.pendingMessageMetadata = pendingMessageMetadata
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case message
        case pendingMessageMetadata = "pending_message_metadata"
    }

    static func == (lhs: GetMessageResponse, rhs: GetMessageResponse) -> Bool {
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
