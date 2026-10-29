//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic response information
final class GetDraftResponse: Sendable, Decodable {
    let draft: DraftPayload

    init(draft: DraftPayload) {
        self.draft = draft
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.draft = try container.decode(DraftPayload.self, forKey: .draft)
    }
}
