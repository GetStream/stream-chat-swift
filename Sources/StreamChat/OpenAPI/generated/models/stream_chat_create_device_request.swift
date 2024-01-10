//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCreateDeviceRequest: Codable, Hashable {
    public var pushProviderName: String?
    
    public var voipToken: Bool?
    
    public var id: String?
    
    public var pushProvider: String?
    
    public init(pushProviderName: String?, voipToken: Bool?, id: String?, pushProvider: String?) {
        self.pushProviderName = pushProviderName
        
        self.voipToken = voipToken
        
        self.id = id
        
        self.pushProvider = pushProvider
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pushProviderName = "push_provider_name"
        
        case voipToken = "voip_token"
        
        case id
        
        case pushProvider = "push_provider"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pushProviderName, forKey: .pushProviderName)
        
        try container.encode(voipToken, forKey: .voipToken)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(pushProvider, forKey: .pushProvider)
    }
}
