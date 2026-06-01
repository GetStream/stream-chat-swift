//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsNotificationParentActivity: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var attachments: [Attachment]?
    var id: String
    var text: String?
    var type: String?
    var userId: String?

    init(attachments: [Attachment]? = nil, id: String, text: String? = nil, userId: String? = nil) {
        self.attachments = attachments
        self.id = id
        self.text = text
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case id
        case text
        case type
        case userId = "user_id"
    }

    static func == (lhs: FeedsNotificationParentActivity, rhs: FeedsNotificationParentActivity) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.id == rhs.id &&
            lhs.text == rhs.text &&
            lhs.type == rhs.type &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(id)
        hasher.combine(text)
        hasher.combine(type)
        hasher.combine(userId)
    }
}
