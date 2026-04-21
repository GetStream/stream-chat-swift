//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUsersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var membershipDeletionTaskId: String
    /// Object containing users
    var users: [String: FullUserResponse]

    init(duration: String, membershipDeletionTaskId: String, users: [String: FullUserResponse]) {
        self.duration = duration
        self.membershipDeletionTaskId = membershipDeletionTaskId
        self.users = users
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case membershipDeletionTaskId = "membership_deletion_task_id"
        case users
    }

    static func == (lhs: UpdateUsersResponse, rhs: UpdateUsersResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.membershipDeletionTaskId == rhs.membershipDeletionTaskId &&
            lhs.users == rhs.users
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(membershipDeletionTaskId)
        hasher.combine(users)
    }
}
