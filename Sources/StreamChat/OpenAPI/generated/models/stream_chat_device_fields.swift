//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeviceFields: Codable, Hashable {
    public var id: String
    
    public var pushProvider: String
    
    public var pushProviderName: String? = nil
    
    public var voip: Bool? = nil
    
    public init(id: String, pushProvider: String, pushProviderName: String? = nil, voip: Bool? = nil) {
        self.id = id
        
        self.pushProvider = pushProvider
        
        self.pushProviderName = pushProviderName
        
        self.voip = voip
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case pushProvider = "push_provider"
        
        case pushProviderName = "push_provider_name"
        
        case voip
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(pushProvider, forKey: .pushProvider)
        
        try container.encode(pushProviderName, forKey: .pushProviderName)
        
        try container.encode(voip, forKey: .voip)
    }
}
