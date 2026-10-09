//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryDraftsResponse: Sendable, Decodable {
    /// Drafts
    let drafts: [DraftPayload]
    let next: String?
    let prev: String?

    init(drafts: [DraftPayload], next: String? = nil, prev: String? = nil) {
        self.drafts = drafts
        self.next = next
        self.prev = prev
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.drafts = try container.decodeArrayIgnoringFailures([DraftPayload].self, forKey: .drafts)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.prev = try container.decodeIfPresent(String.self, forKey: .prev)
    }
}
