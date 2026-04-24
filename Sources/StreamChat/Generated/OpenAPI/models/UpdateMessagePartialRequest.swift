//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMessagePartialRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Sets new field values
    var set: [String: RawJSON]?
    /// Skip enriching the URL in the message
    var skipEnrichUrl: Bool?
    var skipPush: Bool?
    /// [RawJSON] of field names to unset
    var unset: [String]?

    init(set: [String: RawJSON]? = nil, skipEnrichUrl: Bool? = nil, skipPush: Bool? = nil, unset: [String]? = nil) {
        self.set = set
        self.skipEnrichUrl = skipEnrichUrl
        self.skipPush = skipPush
        self.unset = unset
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case set
        case skipEnrichUrl = "skip_enrich_url"
        case skipPush = "skip_push"
        case unset
    }

    static func == (lhs: UpdateMessagePartialRequest, rhs: UpdateMessagePartialRequest) -> Bool {
        lhs.set == rhs.set &&
            lhs.skipEnrichUrl == rhs.skipEnrichUrl &&
            lhs.skipPush == rhs.skipPush &&
            lhs.unset == rhs.unset
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(set)
        hasher.combine(skipEnrichUrl)
        hasher.combine(skipPush)
        hasher.combine(unset)
    }
}
