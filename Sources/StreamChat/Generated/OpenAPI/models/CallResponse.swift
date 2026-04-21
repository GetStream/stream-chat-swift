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
    var createdAt: Timestamp
    var createdBy: UserResponse
    var currentSessionId: String
    var custom: [String: RawJSON]
    var egress: EgressResponse
    var endedAt: Timestamp?
    var id: String
    var ingress: CallIngressResponse
    var joinAheadTimeSeconds: Int?
    var recording: Bool
    var routingNumber: String?
    var session: CallSessionResponse?
    var settings: CallSettingsResponse
    var startsAt: Timestamp?
    var team: String?
    var thumbnails: ThumbnailResponse?
    var transcribing: Bool
    var translating: Bool
    var type: String
    var updatedAt: Timestamp

    init(backstage: Bool, blockedUserIds: [String], captioning: Bool, channelCid: String? = nil, cid: String, createdAt: Timestamp, createdBy: UserResponse, currentSessionId: String, custom: [String: RawJSON], egress: EgressResponse, endedAt: Timestamp? = nil, id: String, ingress: CallIngressResponse, joinAheadTimeSeconds: Int? = nil, recording: Bool, routingNumber: String? = nil, session: CallSessionResponse? = nil, settings: CallSettingsResponse, startsAt: Timestamp? = nil, team: String? = nil, thumbnails: ThumbnailResponse? = nil, transcribing: Bool, translating: Bool, type: String, updatedAt: Timestamp) {
        self.backstage = backstage
        self.blockedUserIds = blockedUserIds
        self.captioning = captioning
        self.channelCid = channelCid
        self.cid = cid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.currentSessionId = currentSessionId
        self.custom = custom
        self.egress = egress
        self.endedAt = endedAt
        self.id = id
        self.ingress = ingress
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
        self.recording = recording
        self.routingNumber = routingNumber
        self.session = session
        self.settings = settings
        self.startsAt = startsAt
        self.team = team
        self.thumbnails = thumbnails
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
        case egress
        case endedAt = "ended_at"
        case id
        case ingress
        case joinAheadTimeSeconds = "join_ahead_time_seconds"
        case recording
        case routingNumber = "routing_number"
        case session
        case settings
        case startsAt = "starts_at"
        case team
        case thumbnails
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
            lhs.egress == rhs.egress &&
            lhs.endedAt == rhs.endedAt &&
            lhs.id == rhs.id &&
            lhs.ingress == rhs.ingress &&
            lhs.joinAheadTimeSeconds == rhs.joinAheadTimeSeconds &&
            lhs.recording == rhs.recording &&
            lhs.routingNumber == rhs.routingNumber &&
            lhs.session == rhs.session &&
            lhs.settings == rhs.settings &&
            lhs.startsAt == rhs.startsAt &&
            lhs.team == rhs.team &&
            lhs.thumbnails == rhs.thumbnails &&
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
        hasher.combine(egress)
        hasher.combine(endedAt)
        hasher.combine(id)
        hasher.combine(ingress)
        hasher.combine(joinAheadTimeSeconds)
        hasher.combine(recording)
        hasher.combine(routingNumber)
        hasher.combine(session)
        hasher.combine(settings)
        hasher.combine(startsAt)
        hasher.combine(team)
        hasher.combine(thumbnails)
        hasher.combine(transcribing)
        hasher.combine(translating)
        hasher.combine(type)
        hasher.combine(updatedAt)
    }
}
