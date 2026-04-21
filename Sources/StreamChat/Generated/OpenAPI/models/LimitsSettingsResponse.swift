//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class LimitsSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var maxDurationSeconds: Int?
    var maxParticipants: Int?
    var maxParticipantsExcludeOwner: Bool?
    var maxParticipantsExcludeRoles: [String]

    init(maxDurationSeconds: Int? = nil, maxParticipants: Int? = nil, maxParticipantsExcludeOwner: Bool? = nil, maxParticipantsExcludeRoles: [String]) {
        self.maxDurationSeconds = maxDurationSeconds
        self.maxParticipants = maxParticipants
        self.maxParticipantsExcludeOwner = maxParticipantsExcludeOwner
        self.maxParticipantsExcludeRoles = maxParticipantsExcludeRoles
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case maxDurationSeconds = "max_duration_seconds"
        case maxParticipants = "max_participants"
        case maxParticipantsExcludeOwner = "max_participants_exclude_owner"
        case maxParticipantsExcludeRoles = "max_participants_exclude_roles"
    }

    static func == (lhs: LimitsSettingsResponse, rhs: LimitsSettingsResponse) -> Bool {
        lhs.maxDurationSeconds == rhs.maxDurationSeconds &&
            lhs.maxParticipants == rhs.maxParticipants &&
            lhs.maxParticipantsExcludeOwner == rhs.maxParticipantsExcludeOwner &&
            lhs.maxParticipantsExcludeRoles == rhs.maxParticipantsExcludeRoles
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(maxDurationSeconds)
        hasher.combine(maxParticipants)
        hasher.combine(maxParticipantsExcludeOwner)
        hasher.combine(maxParticipantsExcludeRoles)
    }
}
