//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMessageRequest: Sendable, Encodable, JSONEncodable {
    /// Message data for creating or updating a message
    let message: MessageRequest
    /// Skip enrich URL
    let skipEnrichUrl: Bool?
    let skipPush: Bool?

    init(
        message: MessageRequest,
        skipEnrichUrl: Bool? = nil,
        skipPush: Bool? = nil
    ) {
        self.message = message
        self.skipEnrichUrl = skipEnrichUrl
        self.skipPush = skipPush
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        case skipEnrichUrl = "skip_enrich_url"
        case skipPush = "skip_push"
    }
}
