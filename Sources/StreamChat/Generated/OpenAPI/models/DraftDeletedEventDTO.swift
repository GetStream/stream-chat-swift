//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DraftDeletedEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel where the draft was created
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let draft: DraftPayload?
    /// The ID of the parent message
    let parentId: String?
    let receivedAt: Date?
    /// The type of event: "draft.deleted" in this case
    let type: String

    init(
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        draft: DraftPayload? = nil,
        parentId: String? = nil,
        receivedAt: Date? = nil,
        type: String = "draft.deleted"
    ) {
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.draft = draft
        self.parentId = parentId
        self.receivedAt = receivedAt
        self.type = type
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
}
