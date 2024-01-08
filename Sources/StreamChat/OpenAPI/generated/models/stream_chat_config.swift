//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatConfig: Codable, Hashable {
    public var roleMap: [String: RawJSON]?
    
    public var appCertificate: String
    
    public var appId: String
    
    public var defaultRole: String?
    
    public init(roleMap: [String: RawJSON]?, appCertificate: String, appId: String, defaultRole: String?) {
        self.roleMap = roleMap
        
        self.appCertificate = appCertificate
        
        self.appId = appId
        
        self.defaultRole = defaultRole
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case roleMap = "role_map"
        
        case appCertificate = "app_certificate"
        
        case appId = "app_id"
        
        case defaultRole = "default_role"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(roleMap, forKey: .roleMap)
        
        try container.encode(appCertificate, forKey: .appCertificate)
        
        try container.encode(appId, forKey: .appId)
        
        try container.encode(defaultRole, forKey: .defaultRole)
    }
}
