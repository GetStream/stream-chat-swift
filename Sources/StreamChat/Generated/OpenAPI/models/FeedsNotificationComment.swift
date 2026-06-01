//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsNotificationComment: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var attachments: [Attachment]?
    var comment: String
    var id: String
    var userId: String

    init(attachments: [Attachment]? = nil, comment: String, id: String, userId: String) {
        self.attachments = attachments
        self.comment = comment
        self.id = id
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case comment
        case id
        case userId = "user_id"
    }

    static func == (lhs: FeedsNotificationComment, rhs: FeedsNotificationComment) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.comment == rhs.comment &&
            lhs.id == rhs.id &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(comment)
        hasher.combine(id)
        hasher.combine(userId)
    }
}
