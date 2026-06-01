//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsReactionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var activityId: String
    var commentId: String?
    var createdAt: Date
    var custom: [String: RawJSON]?
    var type: String
    var updatedAt: Date
    var user: UserResponse

    init(activityId: String, commentId: String? = nil, createdAt: Date, custom: [String: RawJSON]? = nil, type: String, updatedAt: Date, user: UserResponse) {
        self.activityId = activityId
        self.commentId = commentId
        self.createdAt = createdAt
        self.custom = custom
        self.type = type
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activityId = "activity_id"
        case commentId = "comment_id"
        case createdAt = "created_at"
        case custom
        case type
        case updatedAt = "updated_at"
        case user
    }

    static func == (lhs: FeedsReactionResponse, rhs: FeedsReactionResponse) -> Bool {
        lhs.activityId == rhs.activityId &&
            lhs.commentId == rhs.commentId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activityId)
        hasher.combine(commentId)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(type)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
