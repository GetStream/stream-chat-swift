//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsNotificationTarget: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var attachments: [Attachment]?
    var comment: FeedsNotificationComment?
    var custom: [String: RawJSON]?
    var id: String
    var name: String?
    var parentActivity: FeedsNotificationParentActivity?
    var text: String?
    var type: String?
    var userId: String?

    init(attachments: [Attachment]? = nil, comment: FeedsNotificationComment? = nil, custom: [String: RawJSON]? = nil, id: String, name: String? = nil, parentActivity: FeedsNotificationParentActivity? = nil, text: String? = nil, userId: String? = nil) {
        self.attachments = attachments
        self.comment = comment
        self.custom = custom
        self.id = id
        self.name = name
        self.parentActivity = parentActivity
        self.text = text
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case comment
        case custom
        case id
        case name
        case parentActivity = "parent_activity"
        case text
        case type
        case userId = "user_id"
    }

    static func == (lhs: FeedsNotificationTarget, rhs: FeedsNotificationTarget) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.comment == rhs.comment &&
            lhs.custom == rhs.custom &&
            lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.parentActivity == rhs.parentActivity &&
            lhs.text == rhs.text &&
            lhs.type == rhs.type &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(comment)
        hasher.combine(custom)
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(parentActivity)
        hasher.combine(text)
        hasher.combine(type)
        hasher.combine(userId)
    }
}
