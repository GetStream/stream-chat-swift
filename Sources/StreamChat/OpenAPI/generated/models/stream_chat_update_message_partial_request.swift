//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateMessagePartialRequest: Codable, Hashable {
    public var set: [String: RawJSON]
    
    public var skipEnrichUrl: Bool?
    
    public var unset: [String]
    
    public init(set: [String: RawJSON], skipEnrichUrl: Bool?, unset: [String]) {
        self.set = set
        
        self.skipEnrichUrl = skipEnrichUrl
        
        self.unset = unset
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case set
        
        case skipEnrichUrl = "skip_enrich_url"
        
        case unset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(skipEnrichUrl, forKey: .skipEnrichUrl)
        
        try container.encode(unset, forKey: .unset)
    }
}
