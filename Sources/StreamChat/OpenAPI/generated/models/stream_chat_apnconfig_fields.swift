//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAPNConfigFields: Codable, Hashable {
    public var development: Bool
    
    public var enabled: Bool
    
    public var host: String?
    
    public var keyId: String?
    
    public var notificationTemplate: String
    
    public var p12Cert: String?
    
    public var authKey: String?
    
    public var bundleId: String?
    
    public var teamId: String?
    
    public var authType: String?
    
    public init(development: Bool, enabled: Bool, host: String?, keyId: String?, notificationTemplate: String, p12Cert: String?, authKey: String?, bundleId: String?, teamId: String?, authType: String?) {
        self.development = development
        
        self.enabled = enabled
        
        self.host = host
        
        self.keyId = keyId
        
        self.notificationTemplate = notificationTemplate
        
        self.p12Cert = p12Cert
        
        self.authKey = authKey
        
        self.bundleId = bundleId
        
        self.teamId = teamId
        
        self.authType = authType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case development
        
        case enabled
        
        case host
        
        case keyId = "key_id"
        
        case notificationTemplate = "notification_template"
        
        case p12Cert = "p12_cert"
        
        case authKey = "auth_key"
        
        case bundleId = "bundle_id"
        
        case teamId = "team_id"
        
        case authType = "auth_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(development, forKey: .development)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(host, forKey: .host)
        
        try container.encode(keyId, forKey: .keyId)
        
        try container.encode(notificationTemplate, forKey: .notificationTemplate)
        
        try container.encode(p12Cert, forKey: .p12Cert)
        
        try container.encode(authKey, forKey: .authKey)
        
        try container.encode(bundleId, forKey: .bundleId)
        
        try container.encode(teamId, forKey: .teamId)
        
        try container.encode(authType, forKey: .authType)
    }
}
