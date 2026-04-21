//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FlagFeedbackResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var labels: [LabelResponse]
    var messageId: String

    init(createdAt: Date, labels: [LabelResponse], messageId: String) {
        self.createdAt = createdAt
        self.labels = labels
        self.messageId = messageId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case labels
        case messageId = "message_id"
    }

    static func == (lhs: FlagFeedbackResponse, rhs: FlagFeedbackResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.labels == rhs.labels &&
            lhs.messageId == rhs.messageId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(labels)
        hasher.combine(messageId)
    }
}
