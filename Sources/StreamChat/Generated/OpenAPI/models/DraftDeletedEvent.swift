//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DraftDeletedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// The CID of the channel where the draft was created
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var draft: DraftResponse?
    /// The ID of the parent message
    var parentId: String?
    var receivedAt: Date?
    /// The type of event: "draft.deleted" in this case
    var type: String = "draft.deleted"

    init(cid: String? = nil, createdAt: Date, custom: [String: RawJSON], draft: DraftResponse? = nil, parentId: String? = nil, receivedAt: Date? = nil) {
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.draft = draft
        self.parentId = parentId
        self.receivedAt = receivedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case custom
        case draft
        case parentId = "parent_id"
        case receivedAt = "received_at"
        case type
    }

    static func == (lhs: DraftDeletedEvent, rhs: DraftDeletedEvent) -> Bool {
        lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.draft == rhs.draft &&
            lhs.parentId == rhs.parentId &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(draft)
        hasher.combine(parentId)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
