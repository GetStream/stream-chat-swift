//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DraftDeletedEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel where the draft was created
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let draft: DraftPayload?
    /// The type of event: "draft.deleted" in this case
    let type: String

    init(cid: ChannelId, createdAt: Date, draft: DraftPayload? = nil, type: String = "draft.deleted") {
        self.cid = cid
        self.createdAt = createdAt
        self.draft = draft
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case draft
        case type
    }
}
