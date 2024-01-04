//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGeofenceResponse: Codable, Hashable {
    public var description: String?
    
    public var name: String
    
    public var type: String?
    
    public var countryCodes: [String]?
    
    public init(description: String?, name: String, type: String?, countryCodes: [String]?) {
        self.description = description
        
        self.name = name
        
        self.type = type
        
        self.countryCodes = countryCodes
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case description
        
        case name
        
        case type
        
        case countryCodes = "country_codes"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(countryCodes, forKey: .countryCodes)
    }
}
