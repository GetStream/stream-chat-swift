//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var backstage: Bool
    var blockedUserIds: [String]
    var captioning: Bool
    var channelCid: String?
    var cid: String
    var createdAt: Date
    var createdBy: UserResponse?
    var currentSessionId: String
    var custom: [String: RawJSON]
    var endedAt: Date?
    var id: String
    var joinAheadTimeSeconds: Int?
    var recording: Bool
    var routingNumber: String?
    var startsAt: Date?
    var team: String?
    var transcribing: Bool
    var translating: Bool
    var type: String
    var updatedAt: Date

    init(backstage: Bool, blockedUserIds: [String], captioning: Bool, channelCid: String? = nil, cid: String, createdAt: Date, createdBy: UserResponse? = nil, currentSessionId: String, custom: [String: RawJSON], endedAt: Date? = nil, id: String, joinAheadTimeSeconds: Int? = nil, recording: Bool, routingNumber: String? = nil, startsAt: Date? = nil, team: String? = nil, transcribing: Bool, translating: Bool, type: String, updatedAt: Date) {
        self.backstage = backstage
        self.blockedUserIds = blockedUserIds
        self.captioning = captioning
        self.channelCid = channelCid
        self.cid = cid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.currentSessionId = currentSessionId
        self.custom = custom
        self.endedAt = endedAt
        self.id = id
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
        self.recording = recording
        self.routingNumber = routingNumber
        self.startsAt = startsAt
        self.team = team
        self.transcribing = transcribing
        self.translating = translating
        self.type = type
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case backstage
        case blockedUserIds = "blocked_user_ids"
        case captioning
        case channelCid = "channel_cid"
        case cid
        case createdAt = "created_at"
        case createdBy = "created_by"
        case currentSessionId = "current_session_id"
        case custom
        case endedAt = "ended_at"
        case id
        case joinAheadTimeSeconds = "join_ahead_time_seconds"
        case recording
        case routingNumber = "routing_number"
        case startsAt = "starts_at"
        case team
        case transcribing
        case translating
        case type
        case updatedAt = "updated_at"
    }

    static func == (lhs: CallResponse, rhs: CallResponse) -> Bool {
        lhs.backstage == rhs.backstage &&
            lhs.blockedUserIds == rhs.blockedUserIds &&
            lhs.captioning == rhs.captioning &&
            lhs.channelCid == rhs.channelCid &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.currentSessionId == rhs.currentSessionId &&
            lhs.custom == rhs.custom &&
            lhs.endedAt == rhs.endedAt &&
            lhs.id == rhs.id &&
            lhs.joinAheadTimeSeconds == rhs.joinAheadTimeSeconds &&
            lhs.recording == rhs.recording &&
            lhs.routingNumber == rhs.routingNumber &&
            lhs.startsAt == rhs.startsAt &&
            lhs.team == rhs.team &&
            lhs.transcribing == rhs.transcribing &&
            lhs.translating == rhs.translating &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(backstage)
        hasher.combine(blockedUserIds)
        hasher.combine(captioning)
        hasher.combine(channelCid)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(currentSessionId)
        hasher.combine(custom)
        hasher.combine(endedAt)
        hasher.combine(id)
        hasher.combine(joinAheadTimeSeconds)
        hasher.combine(recording)
        hasher.combine(routingNumber)
        hasher.combine(startsAt)
        hasher.combine(team)
        hasher.combine(transcribing)
        hasher.combine(translating)
        hasher.combine(type)
        hasher.combine(updatedAt)
    }
}
