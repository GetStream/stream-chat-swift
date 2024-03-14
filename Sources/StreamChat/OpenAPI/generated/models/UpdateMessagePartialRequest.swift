//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateMessagePartialRequest: Codable, Hashable {
    public var skipEnrichUrl: Bool? = nil
    public var unset: [String]? = nil
    public var set: [String: RawJSON]? = nil

    public init(skipEnrichUrl: Bool? = nil, unset: [String]? = nil, set: [String: RawJSON]? = nil) {
        self.skipEnrichUrl = skipEnrichUrl
        self.unset = unset
        self.set = set
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case skipEnrichUrl = "skip_enrich_url"
        case unset
        case set
    }
}
