//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a Draft is created or updated.
final class DraftUpdatedEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel where the draft was created/updated
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let draft: DraftPayload?
    /// The type of event: "draft.updated" in this case
    let type: String

    init(cid: ChannelId, createdAt: Date, draft: DraftPayload? = nil, type: String = "draft.updated") {
        self.cid = cid
        self.createdAt = createdAt
        self.draft = draft
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.draft = try container.decodeIfPresent(DraftPayload.self, forKey: .draft)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
