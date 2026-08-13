//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DraftPayloadResponse: Decodable, Sendable {
    let draft: DraftPayload

    init(draft: DraftPayload) {
        self.draft = draft
    }
}

final class DraftListPayloadResponse: Decodable, Sendable {
    let drafts: [DraftPayload]
    let next: String?

    init(drafts: [DraftPayload], next: String? = nil) {
        self.drafts = drafts
        self.next = next
    }
}
