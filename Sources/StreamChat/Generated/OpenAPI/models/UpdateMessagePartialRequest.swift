//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateMessagePartialRequest: Sendable, Codable, JSONEncodable {
    /// Sets new field values
    let set: [String: RawJSON]?
    /// Skip enriching the URL in the message
    let skipEnrichUrl: Bool?
    let skipPush: Bool?
    /// Array of field names to unset
    let unset: [String]?

    init(
        set: [String: RawJSON]? = nil,
        skipEnrichUrl: Bool? = nil,
        skipPush: Bool? = nil,
        unset: [String]? = nil
    ) {
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
}
