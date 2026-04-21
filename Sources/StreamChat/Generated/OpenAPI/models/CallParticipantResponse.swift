//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallParticipantResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var joinedAt: Timestamp
    var role: String
    var user: UserResponse
    var userSessionId: String

    init(joinedAt: Timestamp, role: String, user: UserResponse, userSessionId: String) {
        self.joinedAt = joinedAt
        self.role = role
        self.user = user
        self.userSessionId = userSessionId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case joinedAt = "joined_at"
        case role
        case user
        case userSessionId = "user_session_id"
    }

    static func == (lhs: CallParticipantResponse, rhs: CallParticipantResponse) -> Bool {
        lhs.joinedAt == rhs.joinedAt &&
            lhs.role == rhs.role &&
            lhs.user == rhs.user &&
            lhs.userSessionId == rhs.userSessionId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(joinedAt)
        hasher.combine(role)
        hasher.combine(user)
        hasher.combine(userSessionId)
    }
}
