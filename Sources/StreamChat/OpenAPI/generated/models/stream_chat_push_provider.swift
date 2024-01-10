//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPushProvider: Codable, Hashable {
    public var apnTopic: String?
    
    public var huaweiAppId: String?
    
    public var xiaomiAppSecret: String?
    
    public var xiaomiPackageName: String?
    
    public var firebaseServerKey: String?
    
    public var updatedAt: String
    
    public var apnP12Cert: String?
    
    public var description: String?
    
    public var apnAuthType: String?
    
    public var apnHost: String?
    
    public var disabledReason: String?
    
    public var firebaseDataTemplate: String?
    
    public var name: String
    
    public var apnAuthKey: String?
    
    public var apnDevelopment: Bool?
    
    public var apnTeamId: String?
    
    public var createdAt: String
    
    public var disabledAt: String?
    
    public var firebaseCredentials: String?
    
    public var firebaseNotificationTemplate: String?
    
    public var huaweiAppSecret: String?
    
    public var apnKeyId: String?
    
    public var apnNotificationTemplate: String?
    
    public var firebaseApnTemplate: String?
    
    public var firebaseHost: String?
    
    public var type: Int
    
    public init(apnTopic: String?, huaweiAppId: String?, xiaomiAppSecret: String?, xiaomiPackageName: String?, firebaseServerKey: String?, updatedAt: String, apnP12Cert: String?, description: String?, apnAuthType: String?, apnHost: String?, disabledReason: String?, firebaseDataTemplate: String?, name: String, apnAuthKey: String?, apnDevelopment: Bool?, apnTeamId: String?, createdAt: String, disabledAt: String?, firebaseCredentials: String?, firebaseNotificationTemplate: String?, huaweiAppSecret: String?, apnKeyId: String?, apnNotificationTemplate: String?, firebaseApnTemplate: String?, firebaseHost: String?, type: Int) {
        self.apnTopic = apnTopic
        
        self.huaweiAppId = huaweiAppId
        
        self.xiaomiAppSecret = xiaomiAppSecret
        
        self.xiaomiPackageName = xiaomiPackageName
        
        self.firebaseServerKey = firebaseServerKey
        
        self.updatedAt = updatedAt
        
        self.apnP12Cert = apnP12Cert
        
        self.description = description
        
        self.apnAuthType = apnAuthType
        
        self.apnHost = apnHost
        
        self.disabledReason = disabledReason
        
        self.firebaseDataTemplate = firebaseDataTemplate
        
        self.name = name
        
        self.apnAuthKey = apnAuthKey
        
        self.apnDevelopment = apnDevelopment
        
        self.apnTeamId = apnTeamId
        
        self.createdAt = createdAt
        
        self.disabledAt = disabledAt
        
        self.firebaseCredentials = firebaseCredentials
        
        self.firebaseNotificationTemplate = firebaseNotificationTemplate
        
        self.huaweiAppSecret = huaweiAppSecret
        
        self.apnKeyId = apnKeyId
        
        self.apnNotificationTemplate = apnNotificationTemplate
        
        self.firebaseApnTemplate = firebaseApnTemplate
        
        self.firebaseHost = firebaseHost
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case apnTopic = "apn_topic"
        
        case huaweiAppId = "huawei_app_id"
        
        case xiaomiAppSecret = "xiaomi_app_secret"
        
        case xiaomiPackageName = "xiaomi_package_name"
        
        case firebaseServerKey = "firebase_server_key"
        
        case updatedAt = "updated_at"
        
        case apnP12Cert = "apn_p12_cert"
        
        case description
        
        case apnAuthType = "apn_auth_type"
        
        case apnHost = "apn_host"
        
        case disabledReason = "disabled_reason"
        
        case firebaseDataTemplate = "firebase_data_template"
        
        case name
        
        case apnAuthKey = "apn_auth_key"
        
        case apnDevelopment = "apn_development"
        
        case apnTeamId = "apn_team_id"
        
        case createdAt = "created_at"
        
        case disabledAt = "disabled_at"
        
        case firebaseCredentials = "firebase_credentials"
        
        case firebaseNotificationTemplate = "firebase_notification_template"
        
        case huaweiAppSecret = "huawei_app_secret"
        
        case apnKeyId = "apn_key_id"
        
        case apnNotificationTemplate = "apn_notification_template"
        
        case firebaseApnTemplate = "firebase_apn_template"
        
        case firebaseHost = "firebase_host"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(apnTopic, forKey: .apnTopic)
        
        try container.encode(huaweiAppId, forKey: .huaweiAppId)
        
        try container.encode(xiaomiAppSecret, forKey: .xiaomiAppSecret)
        
        try container.encode(xiaomiPackageName, forKey: .xiaomiPackageName)
        
        try container.encode(firebaseServerKey, forKey: .firebaseServerKey)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(apnP12Cert, forKey: .apnP12Cert)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(apnAuthType, forKey: .apnAuthType)
        
        try container.encode(apnHost, forKey: .apnHost)
        
        try container.encode(disabledReason, forKey: .disabledReason)
        
        try container.encode(firebaseDataTemplate, forKey: .firebaseDataTemplate)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(apnAuthKey, forKey: .apnAuthKey)
        
        try container.encode(apnDevelopment, forKey: .apnDevelopment)
        
        try container.encode(apnTeamId, forKey: .apnTeamId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabledAt, forKey: .disabledAt)
        
        try container.encode(firebaseCredentials, forKey: .firebaseCredentials)
        
        try container.encode(firebaseNotificationTemplate, forKey: .firebaseNotificationTemplate)
        
        try container.encode(huaweiAppSecret, forKey: .huaweiAppSecret)
        
        try container.encode(apnKeyId, forKey: .apnKeyId)
        
        try container.encode(apnNotificationTemplate, forKey: .apnNotificationTemplate)
        
        try container.encode(firebaseApnTemplate, forKey: .firebaseApnTemplate)
        
        try container.encode(firebaseHost, forKey: .firebaseHost)
        
        try container.encode(type, forKey: .type)
    }
}
