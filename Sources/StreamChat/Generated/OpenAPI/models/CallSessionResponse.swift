//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallSessionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var acceptedBy: [String: Timestamp]
    var anonymousParticipantCount: Int
    var endedAt: Timestamp?
    var id: String
    var liveEndedAt: Timestamp?
    var liveStartedAt: Timestamp?
    var missedBy: [String: Timestamp]
    var participants: [CallParticipantResponse]
    var participantsCountByRole: [String: Int]
    var rejectedBy: [String: Timestamp]
    var startedAt: Timestamp?
    var timerEndsAt: Timestamp?

    init(acceptedBy: [String: Timestamp], anonymousParticipantCount: Int, endedAt: Timestamp? = nil, id: String, liveEndedAt: Timestamp? = nil, liveStartedAt: Timestamp? = nil, missedBy: [String: Timestamp], participants: [CallParticipantResponse], participantsCountByRole: [String: Int], rejectedBy: [String: Timestamp], startedAt: Timestamp? = nil, timerEndsAt: Timestamp? = nil) {
        self.acceptedBy = acceptedBy
        self.anonymousParticipantCount = anonymousParticipantCount
        self.endedAt = endedAt
        self.id = id
        self.liveEndedAt = liveEndedAt
        self.liveStartedAt = liveStartedAt
        self.missedBy = missedBy
        self.participants = participants
        self.participantsCountByRole = participantsCountByRole
        self.rejectedBy = rejectedBy
        self.startedAt = startedAt
        self.timerEndsAt = timerEndsAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case acceptedBy = "accepted_by"
        case anonymousParticipantCount = "anonymous_participant_count"
        case endedAt = "ended_at"
        case id
        case liveEndedAt = "live_ended_at"
        case liveStartedAt = "live_started_at"
        case missedBy = "missed_by"
        case participants
        case participantsCountByRole = "participants_count_by_role"
        case rejectedBy = "rejected_by"
        case startedAt = "started_at"
        case timerEndsAt = "timer_ends_at"
    }

    static func == (lhs: CallSessionResponse, rhs: CallSessionResponse) -> Bool {
        lhs.acceptedBy == rhs.acceptedBy &&
            lhs.anonymousParticipantCount == rhs.anonymousParticipantCount &&
            lhs.endedAt == rhs.endedAt &&
            lhs.id == rhs.id &&
            lhs.liveEndedAt == rhs.liveEndedAt &&
            lhs.liveStartedAt == rhs.liveStartedAt &&
            lhs.missedBy == rhs.missedBy &&
            lhs.participants == rhs.participants &&
            lhs.participantsCountByRole == rhs.participantsCountByRole &&
            lhs.rejectedBy == rhs.rejectedBy &&
            lhs.startedAt == rhs.startedAt &&
            lhs.timerEndsAt == rhs.timerEndsAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(acceptedBy)
        hasher.combine(anonymousParticipantCount)
        hasher.combine(endedAt)
        hasher.combine(id)
        hasher.combine(liveEndedAt)
        hasher.combine(liveStartedAt)
        hasher.combine(missedBy)
        hasher.combine(participants)
        hasher.combine(participantsCountByRole)
        hasher.combine(rejectedBy)
        hasher.combine(startedAt)
        hasher.combine(timerEndsAt)
    }
}
