//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGeofenceResponse: Codable, Hashable {
    public var countryCodes: [String]?
    
    public var description: String?
    
    public var name: String
    
    public var type: String?
    
    public init(countryCodes: [String]?, description: String?, name: String, type: String?) {
        self.countryCodes = countryCodes
        
        self.description = description
        
        self.name = name
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case countryCodes = "country_codes"
        
        case description
        
        case name
        
        case type
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(countryCodes, forKey: .countryCodes)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(type, forKey: .type)
    }
}
