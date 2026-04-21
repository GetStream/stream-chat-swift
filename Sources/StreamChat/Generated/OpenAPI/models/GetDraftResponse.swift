//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetDraftResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var draft: DraftResponse
    /// Duration of the request in milliseconds
    var duration: String

    init(draft: DraftResponse, duration: String) {
        self.draft = draft
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case draft
        case duration
    }

    static func == (lhs: GetDraftResponse, rhs: GetDraftResponse) -> Bool {
        lhs.draft == rhs.draft &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(draft)
        hasher.combine(duration)
    }
}
