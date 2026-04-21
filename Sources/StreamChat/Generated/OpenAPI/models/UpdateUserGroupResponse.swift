//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUserGroupResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    var userGroup: UserGroupResponse?

    init(duration: String, userGroup: UserGroupResponse? = nil) {
        self.duration = duration
        self.userGroup = userGroup
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case userGroup = "user_group"
    }

    static func == (lhs: UpdateUserGroupResponse, rhs: UpdateUserGroupResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.userGroup == rhs.userGroup
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(userGroup)
    }
}
