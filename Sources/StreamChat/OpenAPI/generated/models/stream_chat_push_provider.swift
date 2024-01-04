//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPushProvider: Codable, Hashable {
    public var createdAt: String
    
    public var disabledAt: String?
    
    public var firebaseNotificationTemplate: String?
    
    public var firebaseServerKey: String?
    
    public var xiaomiAppSecret: String?
    
    public var apnP12Cert: String?
    
    public var huaweiAppId: String?
    
    public var updatedAt: String
    
    public var xiaomiPackageName: String?
    
    public var apnNotificationTemplate: String?
    
    public var disabledReason: String?
    
    public var firebaseApnTemplate: String?
    
    public var firebaseHost: String?
    
    public var apnAuthType: String?
    
    public var apnDevelopment: Bool?
    
    public var apnAuthKey: String?
    
    public var apnHost: String?
    
    public var firebaseCredentials: String?
    
    public var type: Int
    
    public var apnTopic: String?
    
    public var description: String?
    
    public var huaweiAppSecret: String?
    
    public var firebaseDataTemplate: String?
    
    public var name: String
    
    public var apnKeyId: String?
    
    public var apnTeamId: String?
    
    public init(createdAt: String, disabledAt: String?, firebaseNotificationTemplate: String?, firebaseServerKey: String?, xiaomiAppSecret: String?, apnP12Cert: String?, huaweiAppId: String?, updatedAt: String, xiaomiPackageName: String?, apnNotificationTemplate: String?, disabledReason: String?, firebaseApnTemplate: String?, firebaseHost: String?, apnAuthType: String?, apnDevelopment: Bool?, apnAuthKey: String?, apnHost: String?, firebaseCredentials: String?, type: Int, apnTopic: String?, description: String?, huaweiAppSecret: String?, firebaseDataTemplate: String?, name: String, apnKeyId: String?, apnTeamId: String?) {
        self.createdAt = createdAt
        
        self.disabledAt = disabledAt
        
        self.firebaseNotificationTemplate = firebaseNotificationTemplate
        
        self.firebaseServerKey = firebaseServerKey
        
        self.xiaomiAppSecret = xiaomiAppSecret
        
        self.apnP12Cert = apnP12Cert
        
        self.huaweiAppId = huaweiAppId
        
        self.updatedAt = updatedAt
        
        self.xiaomiPackageName = xiaomiPackageName
        
        self.apnNotificationTemplate = apnNotificationTemplate
        
        self.disabledReason = disabledReason
        
        self.firebaseApnTemplate = firebaseApnTemplate
        
        self.firebaseHost = firebaseHost
        
        self.apnAuthType = apnAuthType
        
        self.apnDevelopment = apnDevelopment
        
        self.apnAuthKey = apnAuthKey
        
        self.apnHost = apnHost
        
        self.firebaseCredentials = firebaseCredentials
        
        self.type = type
        
        self.apnTopic = apnTopic
        
        self.description = description
        
        self.huaweiAppSecret = huaweiAppSecret
        
        self.firebaseDataTemplate = firebaseDataTemplate
        
        self.name = name
        
        self.apnKeyId = apnKeyId
        
        self.apnTeamId = apnTeamId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case disabledAt = "disabled_at"
        
        case firebaseNotificationTemplate = "firebase_notification_template"
        
        case firebaseServerKey = "firebase_server_key"
        
        case xiaomiAppSecret = "xiaomi_app_secret"
        
        case apnP12Cert = "apn_p12_cert"
        
        case huaweiAppId = "huawei_app_id"
        
        case updatedAt = "updated_at"
        
        case xiaomiPackageName = "xiaomi_package_name"
        
        case apnNotificationTemplate = "apn_notification_template"
        
        case disabledReason = "disabled_reason"
        
        case firebaseApnTemplate = "firebase_apn_template"
        
        case firebaseHost = "firebase_host"
        
        case apnAuthType = "apn_auth_type"
        
        case apnDevelopment = "apn_development"
        
        case apnAuthKey = "apn_auth_key"
        
        case apnHost = "apn_host"
        
        case firebaseCredentials = "firebase_credentials"
        
        case type
        
        case apnTopic = "apn_topic"
        
        case description
        
        case huaweiAppSecret = "huawei_app_secret"
        
        case firebaseDataTemplate = "firebase_data_template"
        
        case name
        
        case apnKeyId = "apn_key_id"
        
        case apnTeamId = "apn_team_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabledAt, forKey: .disabledAt)
        
        try container.encode(firebaseNotificationTemplate, forKey: .firebaseNotificationTemplate)
        
        try container.encode(firebaseServerKey, forKey: .firebaseServerKey)
        
        try container.encode(xiaomiAppSecret, forKey: .xiaomiAppSecret)
        
        try container.encode(apnP12Cert, forKey: .apnP12Cert)
        
        try container.encode(huaweiAppId, forKey: .huaweiAppId)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(xiaomiPackageName, forKey: .xiaomiPackageName)
        
        try container.encode(apnNotificationTemplate, forKey: .apnNotificationTemplate)
        
        try container.encode(disabledReason, forKey: .disabledReason)
        
        try container.encode(firebaseApnTemplate, forKey: .firebaseApnTemplate)
        
        try container.encode(firebaseHost, forKey: .firebaseHost)
        
        try container.encode(apnAuthType, forKey: .apnAuthType)
        
        try container.encode(apnDevelopment, forKey: .apnDevelopment)
        
        try container.encode(apnAuthKey, forKey: .apnAuthKey)
        
        try container.encode(apnHost, forKey: .apnHost)
        
        try container.encode(firebaseCredentials, forKey: .firebaseCredentials)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(apnTopic, forKey: .apnTopic)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(huaweiAppSecret, forKey: .huaweiAppSecret)
        
        try container.encode(firebaseDataTemplate, forKey: .firebaseDataTemplate)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(apnKeyId, forKey: .apnKeyId)
        
        try container.encode(apnTeamId, forKey: .apnTeamId)
    }
}
