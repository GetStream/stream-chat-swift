//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAPNConfigFields: Codable, Hashable {
    public var host: String?
    
    public var keyId: String?
    
    public var notificationTemplate: String
    
    public var development: Bool
    
    public var enabled: Bool
    
    public var bundleId: String?
    
    public var p12Cert: String?
    
    public var teamId: String?
    
    public var authKey: String?
    
    public var authType: String?
    
    public init(host: String?, keyId: String?, notificationTemplate: String, development: Bool, enabled: Bool, bundleId: String?, p12Cert: String?, teamId: String?, authKey: String?, authType: String?) {
        self.host = host
        
        self.keyId = keyId
        
        self.notificationTemplate = notificationTemplate
        
        self.development = development
        
        self.enabled = enabled
        
        self.bundleId = bundleId
        
        self.p12Cert = p12Cert
        
        self.teamId = teamId
        
        self.authKey = authKey
        
        self.authType = authType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case host
        
        case keyId = "key_id"
        
        case notificationTemplate = "notification_template"
        
        case development
        
        case enabled
        
        case bundleId = "bundle_id"
        
        case p12Cert = "p12_cert"
        
        case teamId = "team_id"
        
        case authKey = "auth_key"
        
        case authType = "auth_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(host, forKey: .host)
        
        try container.encode(keyId, forKey: .keyId)
        
        try container.encode(notificationTemplate, forKey: .notificationTemplate)
        
        try container.encode(development, forKey: .development)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(bundleId, forKey: .bundleId)
        
        try container.encode(p12Cert, forKey: .p12Cert)
        
        try container.encode(teamId, forKey: .teamId)
        
        try container.encode(authKey, forKey: .authKey)
        
        try container.encode(authType, forKey: .authType)
    }
}
