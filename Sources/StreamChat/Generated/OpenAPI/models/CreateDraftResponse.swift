//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class CreateDraftResponse: Sendable, Decodable {
    let draft: DraftPayload

    init(draft: DraftPayload) {
        self.draft = draft
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case draft
    }
}
