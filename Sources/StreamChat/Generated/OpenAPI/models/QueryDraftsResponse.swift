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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case drafts
        case next
        case prev
    }
}
