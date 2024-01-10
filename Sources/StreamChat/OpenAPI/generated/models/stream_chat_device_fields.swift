//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeviceFields: Codable, Hashable {
    public var pushProvider: String
    
    public var pushProviderName: String?
    
    public var voip: Bool?
    
    public var id: String
    
    public init(pushProvider: String, pushProviderName: String?, voip: Bool?, id: String) {
        self.pushProvider = pushProvider
        
        self.pushProviderName = pushProviderName
        
        self.voip = voip
        
        self.id = id
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pushProvider = "push_provider"
        
        case pushProviderName = "push_provider_name"
        
        case voip
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pushProvider, forKey: .pushProvider)
        
        try container.encode(pushProviderName, forKey: .pushProviderName)
        
        try container.encode(voip, forKey: .voip)
        
        try container.encode(id, forKey: .id)
    }
}
