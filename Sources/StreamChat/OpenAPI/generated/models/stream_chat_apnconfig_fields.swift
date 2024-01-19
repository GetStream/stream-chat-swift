//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAPNConfigFields: Codable, Hashable {
    public var p12Cert: String?
    
    public var authType: String?
    
    public var bundleId: String?
    
    public var keyId: String?
    
    public var notificationTemplate: String
    
    public var teamId: String?
    
    public var authKey: String?
    
    public var development: Bool
    
    public var enabled: Bool
    
    public var host: String?
    
    public init(p12Cert: String?, authType: String?, bundleId: String?, keyId: String?, notificationTemplate: String, teamId: String?, authKey: String?, development: Bool, enabled: Bool, host: String?) {
        self.p12Cert = p12Cert
        
        self.authType = authType
        
        self.bundleId = bundleId
        
        self.keyId = keyId
        
        self.notificationTemplate = notificationTemplate
        
        self.teamId = teamId
        
        self.authKey = authKey
        
        self.development = development
        
        self.enabled = enabled
        
        self.host = host
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case p12Cert = "p12_cert"
        
        case authType = "auth_type"
        
        case bundleId = "bundle_id"
        
        case keyId = "key_id"
        
        case notificationTemplate = "notification_template"
        
        case teamId = "team_id"
        
        case authKey = "auth_key"
        
        case development
        
        case enabled
        
        case host
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(p12Cert, forKey: .p12Cert)
        
        try container.encode(authType, forKey: .authType)
        
        try container.encode(bundleId, forKey: .bundleId)
        
        try container.encode(keyId, forKey: .keyId)
        
        try container.encode(notificationTemplate, forKey: .notificationTemplate)
        
        try container.encode(teamId, forKey: .teamId)
        
        try container.encode(authKey, forKey: .authKey)
        
        try container.encode(development, forKey: .development)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(host, forKey: .host)
    }
}
