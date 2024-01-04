//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAPNConfigFields: Codable, Hashable {
    public var authKey: String?
    
    public var development: Bool
    
    public var host: String?
    
    public var keyId: String?
    
    public var notificationTemplate: String
    
    public var p12Cert: String?
    
    public var teamId: String?
    
    public var authType: String?
    
    public var bundleId: String?
    
    public var enabled: Bool
    
    public init(authKey: String?, development: Bool, host: String?, keyId: String?, notificationTemplate: String, p12Cert: String?, teamId: String?, authType: String?, bundleId: String?, enabled: Bool) {
        self.authKey = authKey
        
        self.development = development
        
        self.host = host
        
        self.keyId = keyId
        
        self.notificationTemplate = notificationTemplate
        
        self.p12Cert = p12Cert
        
        self.teamId = teamId
        
        self.authType = authType
        
        self.bundleId = bundleId
        
        self.enabled = enabled
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case authKey = "auth_key"
        
        case development
        
        case host
        
        case keyId = "key_id"
        
        case notificationTemplate = "notification_template"
        
        case p12Cert = "p12_cert"
        
        case teamId = "team_id"
        
        case authType = "auth_type"
        
        case bundleId = "bundle_id"
        
        case enabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(authKey, forKey: .authKey)
        
        try container.encode(development, forKey: .development)
        
        try container.encode(host, forKey: .host)
        
        try container.encode(keyId, forKey: .keyId)
        
        try container.encode(notificationTemplate, forKey: .notificationTemplate)
        
        try container.encode(p12Cert, forKey: .p12Cert)
        
        try container.encode(teamId, forKey: .teamId)
        
        try container.encode(authType, forKey: .authType)
        
        try container.encode(bundleId, forKey: .bundleId)
        
        try container.encode(enabled, forKey: .enabled)
    }
}
