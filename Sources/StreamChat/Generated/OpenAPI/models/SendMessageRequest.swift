//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendMessageRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var keepChannelHidden: Bool?
    var message: MessageRequest
    var skipEnrichUrl: Bool?
    var skipPush: Bool?

    init(keepChannelHidden: Bool? = nil, message: MessageRequest, skipEnrichUrl: Bool? = nil, skipPush: Bool? = nil) {
        self.keepChannelHidden = keepChannelHidden
        self.message = message
        self.skipEnrichUrl = skipEnrichUrl
        self.skipPush = skipPush
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case keepChannelHidden = "keep_channel_hidden"
        case message
        case skipEnrichUrl = "skip_enrich_url"
        case skipPush = "skip_push"
    }

    static func == (lhs: SendMessageRequest, rhs: SendMessageRequest) -> Bool {
        lhs.keepChannelHidden == rhs.keepChannelHidden &&
            lhs.message == rhs.message &&
            lhs.skipEnrichUrl == rhs.skipEnrichUrl &&
            lhs.skipPush == rhs.skipPush
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keepChannelHidden)
        hasher.combine(message)
        hasher.combine(skipEnrichUrl)
        hasher.combine(skipPush)
    }
}
