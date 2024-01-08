//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPushProvider: Codable, Hashable {
    public var apnTeamId: String?
    
    public var updatedAt: String
    
    public var xiaomiPackageName: String?
    
    public var apnNotificationTemplate: String?
    
    public var firebaseHost: String?
    
    public var name: String
    
    public var apnTopic: String?
    
    public var disabledReason: String?
    
    public var huaweiAppSecret: String?
    
    public var firebaseApnTemplate: String?
    
    public var firebaseServerKey: String?
    
    public var type: Int
    
    public var firebaseCredentials: String?
    
    public var firebaseDataTemplate: String?
    
    public var xiaomiAppSecret: String?
    
    public var apnHost: String?
    
    public var apnKeyId: String?
    
    public var apnP12Cert: String?
    
    public var description: String?
    
    public var firebaseNotificationTemplate: String?
    
    public var huaweiAppId: String?
    
    public var apnAuthKey: String?
    
    public var apnAuthType: String?
    
    public var apnDevelopment: Bool?
    
    public var createdAt: String
    
    public var disabledAt: String?
    
    public init(apnTeamId: String?, updatedAt: String, xiaomiPackageName: String?, apnNotificationTemplate: String?, firebaseHost: String?, name: String, apnTopic: String?, disabledReason: String?, huaweiAppSecret: String?, firebaseApnTemplate: String?, firebaseServerKey: String?, type: Int, firebaseCredentials: String?, firebaseDataTemplate: String?, xiaomiAppSecret: String?, apnHost: String?, apnKeyId: String?, apnP12Cert: String?, description: String?, firebaseNotificationTemplate: String?, huaweiAppId: String?, apnAuthKey: String?, apnAuthType: String?, apnDevelopment: Bool?, createdAt: String, disabledAt: String?) {
        self.apnTeamId = apnTeamId
        
        self.updatedAt = updatedAt
        
        self.xiaomiPackageName = xiaomiPackageName
        
        self.apnNotificationTemplate = apnNotificationTemplate
        
        self.firebaseHost = firebaseHost
        
        self.name = name
        
        self.apnTopic = apnTopic
        
        self.disabledReason = disabledReason
        
        self.huaweiAppSecret = huaweiAppSecret
        
        self.firebaseApnTemplate = firebaseApnTemplate
        
        self.firebaseServerKey = firebaseServerKey
        
        self.type = type
        
        self.firebaseCredentials = firebaseCredentials
        
        self.firebaseDataTemplate = firebaseDataTemplate
        
        self.xiaomiAppSecret = xiaomiAppSecret
        
        self.apnHost = apnHost
        
        self.apnKeyId = apnKeyId
        
        self.apnP12Cert = apnP12Cert
        
        self.description = description
        
        self.firebaseNotificationTemplate = firebaseNotificationTemplate
        
        self.huaweiAppId = huaweiAppId
        
        self.apnAuthKey = apnAuthKey
        
        self.apnAuthType = apnAuthType
        
        self.apnDevelopment = apnDevelopment
        
        self.createdAt = createdAt
        
        self.disabledAt = disabledAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case apnTeamId = "apn_team_id"
        
        case updatedAt = "updated_at"
        
        case xiaomiPackageName = "xiaomi_package_name"
        
        case apnNotificationTemplate = "apn_notification_template"
        
        case firebaseHost = "firebase_host"
        
        case name
        
        case apnTopic = "apn_topic"
        
        case disabledReason = "disabled_reason"
        
        case huaweiAppSecret = "huawei_app_secret"
        
        case firebaseApnTemplate = "firebase_apn_template"
        
        case firebaseServerKey = "firebase_server_key"
        
        case type
        
        case firebaseCredentials = "firebase_credentials"
        
        case firebaseDataTemplate = "firebase_data_template"
        
        case xiaomiAppSecret = "xiaomi_app_secret"
        
        case apnHost = "apn_host"
        
        case apnKeyId = "apn_key_id"
        
        case apnP12Cert = "apn_p12_cert"
        
        case description
        
        case firebaseNotificationTemplate = "firebase_notification_template"
        
        case huaweiAppId = "huawei_app_id"
        
        case apnAuthKey = "apn_auth_key"
        
        case apnAuthType = "apn_auth_type"
        
        case apnDevelopment = "apn_development"
        
        case createdAt = "created_at"
        
        case disabledAt = "disabled_at"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(apnTeamId, forKey: .apnTeamId)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(xiaomiPackageName, forKey: .xiaomiPackageName)
        
        try container.encode(apnNotificationTemplate, forKey: .apnNotificationTemplate)
        
        try container.encode(firebaseHost, forKey: .firebaseHost)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(apnTopic, forKey: .apnTopic)
        
        try container.encode(disabledReason, forKey: .disabledReason)
        
        try container.encode(huaweiAppSecret, forKey: .huaweiAppSecret)
        
        try container.encode(firebaseApnTemplate, forKey: .firebaseApnTemplate)
        
        try container.encode(firebaseServerKey, forKey: .firebaseServerKey)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(firebaseCredentials, forKey: .firebaseCredentials)
        
        try container.encode(firebaseDataTemplate, forKey: .firebaseDataTemplate)
        
        try container.encode(xiaomiAppSecret, forKey: .xiaomiAppSecret)
        
        try container.encode(apnHost, forKey: .apnHost)
        
        try container.encode(apnKeyId, forKey: .apnKeyId)
        
        try container.encode(apnP12Cert, forKey: .apnP12Cert)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(firebaseNotificationTemplate, forKey: .firebaseNotificationTemplate)
        
        try container.encode(huaweiAppId, forKey: .huaweiAppId)
        
        try container.encode(apnAuthKey, forKey: .apnAuthKey)
        
        try container.encode(apnAuthType, forKey: .apnAuthType)
        
        try container.encode(apnDevelopment, forKey: .apnDevelopment)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabledAt, forKey: .disabledAt)
    }
}
