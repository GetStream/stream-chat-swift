//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsBookmarkResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var activityId: String?
    var createdAt: Date
    var custom: [String: RawJSON]?
    var objectId: String
    var objectType: String
    var updatedAt: Date
    var user: UserResponse

    init(activityId: String? = nil, createdAt: Date, custom: [String: RawJSON]? = nil, objectId: String, objectType: String, updatedAt: Date, user: UserResponse) {
        self.activityId = activityId
        self.createdAt = createdAt
        self.custom = custom
        self.objectId = objectId
        self.objectType = objectType
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activityId = "activity_id"
        case createdAt = "created_at"
        case custom
        case objectId = "object_id"
        case objectType = "object_type"
        case updatedAt = "updated_at"
        case user
    }

    static func == (lhs: FeedsBookmarkResponse, rhs: FeedsBookmarkResponse) -> Bool {
        lhs.activityId == rhs.activityId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.objectId == rhs.objectId &&
            lhs.objectType == rhs.objectType &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activityId)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(objectId)
        hasher.combine(objectType)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
