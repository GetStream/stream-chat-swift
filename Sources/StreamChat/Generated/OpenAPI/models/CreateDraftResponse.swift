//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateDraftResponse: Sendable, Codable, JSONEncodable {
    let draft: DraftPayload

    init(draft: DraftPayload) {
        self.draft = draft
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case draft
    }
}
