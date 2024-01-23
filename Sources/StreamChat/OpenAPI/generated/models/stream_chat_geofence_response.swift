//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGeofenceResponse: Codable, Hashable {
    public var name: String
    
    public var description: String? = nil
    
    public var type: String? = nil
    
    public var countryCodes: [String]? = nil
    
    public init(name: String, description: String? = nil, type: String? = nil, countryCodes: [String]? = nil) {
        self.name = name
        
        self.description = description
        
        self.type = type
        
        self.countryCodes = countryCodes
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case description
        
        case type
        
        case countryCodes = "country_codes"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(countryCodes, forKey: .countryCodes)
    }
}
