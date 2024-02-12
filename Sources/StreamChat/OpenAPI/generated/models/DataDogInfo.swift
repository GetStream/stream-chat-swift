//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DataDogInfo: Codable, Hashable {
    public var apiKey: String
    
    public var site: String
    
    public init(apiKey: String, site: String) {
        self.apiKey = apiKey
        
        self.site = site
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case apiKey = "api_key"
        
        case site
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(apiKey, forKey: .apiKey)
        
        try container.encode(site, forKey: .site)
    }
}
