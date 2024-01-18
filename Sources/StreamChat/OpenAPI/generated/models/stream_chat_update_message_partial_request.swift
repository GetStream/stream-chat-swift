//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateMessagePartialRequest: Codable, Hashable {
    public var unset: [String]
    
    public var set: [String: RawJSON]
    
    public var skipEnrichUrl: Bool?
    
    public init(unset: [String], set: [String: RawJSON], skipEnrichUrl: Bool?) {
        self.unset = unset
        
        self.set = set
        
        self.skipEnrichUrl = skipEnrichUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unset
        
        case set
        
        case skipEnrichUrl = "skip_enrich_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(unset, forKey: .unset)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(skipEnrichUrl, forKey: .skipEnrichUrl)
    }
}
