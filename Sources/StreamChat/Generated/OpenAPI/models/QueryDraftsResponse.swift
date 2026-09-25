//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryDraftsResponse: Sendable, Decodable {
    /// Drafts
    let drafts: [DraftPayload]
    let next: String?

    init(drafts: [DraftPayload], next: String? = nil) {
        self.drafts = drafts
        self.next = next
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case drafts
        case next
    }
}
