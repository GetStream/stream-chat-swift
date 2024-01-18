//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGeofenceResponse: Codable, Hashable {
    public var type: String?
    
    public var countryCodes: [String]?
    
    public var description: String?
    
    public var name: String
    
    public init(type: String?, countryCodes: [String]?, description: String?, name: String) {
        self.type = type
        
        self.countryCodes = countryCodes
        
        self.description = description
        
        self.name = name
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case countryCodes = "country_codes"
        
        case description
        
        case name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(countryCodes, forKey: .countryCodes)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(name, forKey: .name)
    }
}
