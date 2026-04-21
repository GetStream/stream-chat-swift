//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMessageRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var message: MessageRequest
    /// Skip enrich URL
    var skipEnrichUrl: Bool?
    var skipPush: Bool?

    init(message: MessageRequest, skipEnrichUrl: Bool? = nil, skipPush: Bool? = nil) {
        self.message = message
        self.skipEnrichUrl = skipEnrichUrl
        self.skipPush = skipPush
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        case skipEnrichUrl = "skip_enrich_url"
        case skipPush = "skip_push"
    }

    static func == (lhs: UpdateMessageRequest, rhs: UpdateMessageRequest) -> Bool {
        lhs.message == rhs.message &&
            lhs.skipEnrichUrl == rhs.skipEnrichUrl &&
            lhs.skipPush == rhs.skipPush
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(message)
        hasher.combine(skipEnrichUrl)
        hasher.combine(skipPush)
    }
}
