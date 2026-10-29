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

    init(message: MessageRequest, skipEnrichUrl: Bool? = nil, skipPush: Bool? = nil) {
        self.message = message
        self.skipEnrichUrl = skipEnrichUrl
        self.skipPush = skipPush
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(skipEnrichUrl, forKey: .skipEnrichUrl)
        try container.encodeIfPresent(skipPush, forKey: .skipPush)
    }
}
