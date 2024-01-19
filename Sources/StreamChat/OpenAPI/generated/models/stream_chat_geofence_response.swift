//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGeofenceResponse: Codable, Hashable {
    public var name: String
    
    public var type: String?
    
    public var countryCodes: [String]?
    
    public var description: String?
    
    public init(name: String, type: String?, countryCodes: [String]?, description: String?) {
        self.name = name
        
        self.type = type
        
        self.countryCodes = countryCodes
        
        self.description = description
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case type
        
        case countryCodes = "country_codes"
        
        case description
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(countryCodes, forKey: .countryCodes)
        
        try container.encode(description, forKey: .description)
    }
}
