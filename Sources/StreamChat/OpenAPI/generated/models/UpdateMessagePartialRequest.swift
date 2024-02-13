//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateMessagePartialRequest: Codable, Hashable {
    public var unset: [String]
    public var set: [String: RawJSON]
    public var skipEnrichUrl: Bool? = nil

    public init(unset: [String], set: [String: RawJSON], skipEnrichUrl: Bool? = nil) {
        self.unset = unset
        self.set = set
        self.skipEnrichUrl = skipEnrichUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unset
        case set
        case skipEnrichUrl = "skip_enrich_url"
    }
}
