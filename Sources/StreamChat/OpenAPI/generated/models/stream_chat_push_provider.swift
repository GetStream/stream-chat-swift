//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPushProvider: Codable, Hashable {
    public var firebaseApnTemplate: String?
    
    public var firebaseCredentials: String?
    
    public var description: String?
    
    public var firebaseNotificationTemplate: String?
    
    public var huaweiAppId: String?
    
    public var huaweiAppSecret: String?
    
    public var disabledAt: Date?
    
    public var apnNotificationTemplate: String?
    
    public var apnTeamId: String?
    
    public var firebaseServerKey: String?
    
    public var firebaseHost: String?
    
    public var type: Int
    
    public var updatedAt: Date
    
    public var apnAuthKey: String?
    
    public var name: String
    
    public var xiaomiAppSecret: String?
    
    public var apnKeyId: String?
    
    public var disabledReason: String?
    
    public var firebaseDataTemplate: String?
    
    public var apnHost: String?
    
    public var apnDevelopment: Bool?
    
    public var apnTopic: String?
    
    public var createdAt: Date
    
    public var apnAuthType: String?
    
    public var xiaomiPackageName: String?
    
    public var apnP12Cert: String?
    
    public init(firebaseApnTemplate: String?, firebaseCredentials: String?, description: String?, firebaseNotificationTemplate: String?, huaweiAppId: String?, huaweiAppSecret: String?, disabledAt: Date?, apnNotificationTemplate: String?, apnTeamId: String?, firebaseServerKey: String?, firebaseHost: String?, type: Int, updatedAt: Date, apnAuthKey: String?, name: String, xiaomiAppSecret: String?, apnKeyId: String?, disabledReason: String?, firebaseDataTemplate: String?, apnHost: String?, apnDevelopment: Bool?, apnTopic: String?, createdAt: Date, apnAuthType: String?, xiaomiPackageName: String?, apnP12Cert: String?) {
        self.firebaseApnTemplate = firebaseApnTemplate
        
        self.firebaseCredentials = firebaseCredentials
        
        self.description = description
        
        self.firebaseNotificationTemplate = firebaseNotificationTemplate
        
        self.huaweiAppId = huaweiAppId
        
        self.huaweiAppSecret = huaweiAppSecret
        
        self.disabledAt = disabledAt
        
        self.apnNotificationTemplate = apnNotificationTemplate
        
        self.apnTeamId = apnTeamId
        
        self.firebaseServerKey = firebaseServerKey
        
        self.firebaseHost = firebaseHost
        
        self.type = type
        
        self.updatedAt = updatedAt
        
        self.apnAuthKey = apnAuthKey
        
        self.name = name
        
        self.xiaomiAppSecret = xiaomiAppSecret
        
        self.apnKeyId = apnKeyId
        
        self.disabledReason = disabledReason
        
        self.firebaseDataTemplate = firebaseDataTemplate
        
        self.apnHost = apnHost
        
        self.apnDevelopment = apnDevelopment
        
        self.apnTopic = apnTopic
        
        self.createdAt = createdAt
        
        self.apnAuthType = apnAuthType
        
        self.xiaomiPackageName = xiaomiPackageName
        
        self.apnP12Cert = apnP12Cert
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case firebaseApnTemplate = "firebase_apn_template"
        
        case firebaseCredentials = "firebase_credentials"
        
        case description
        
        case firebaseNotificationTemplate = "firebase_notification_template"
        
        case huaweiAppId = "huawei_app_id"
        
        case huaweiAppSecret = "huawei_app_secret"
        
        case disabledAt = "disabled_at"
        
        case apnNotificationTemplate = "apn_notification_template"
        
        case apnTeamId = "apn_team_id"
        
        case firebaseServerKey = "firebase_server_key"
        
        case firebaseHost = "firebase_host"
        
        case type
        
        case updatedAt = "updated_at"
        
        case apnAuthKey = "apn_auth_key"
        
        case name
        
        case xiaomiAppSecret = "xiaomi_app_secret"
        
        case apnKeyId = "apn_key_id"
        
        case disabledReason = "disabled_reason"
        
        case firebaseDataTemplate = "firebase_data_template"
        
        case apnHost = "apn_host"
        
        case apnDevelopment = "apn_development"
        
        case apnTopic = "apn_topic"
        
        case createdAt = "created_at"
        
        case apnAuthType = "apn_auth_type"
        
        case xiaomiPackageName = "xiaomi_package_name"
        
        case apnP12Cert = "apn_p12_cert"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(firebaseApnTemplate, forKey: .firebaseApnTemplate)
        
        try container.encode(firebaseCredentials, forKey: .firebaseCredentials)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(firebaseNotificationTemplate, forKey: .firebaseNotificationTemplate)
        
        try container.encode(huaweiAppId, forKey: .huaweiAppId)
        
        try container.encode(huaweiAppSecret, forKey: .huaweiAppSecret)
        
        try container.encode(disabledAt, forKey: .disabledAt)
        
        try container.encode(apnNotificationTemplate, forKey: .apnNotificationTemplate)
        
        try container.encode(apnTeamId, forKey: .apnTeamId)
        
        try container.encode(firebaseServerKey, forKey: .firebaseServerKey)
        
        try container.encode(firebaseHost, forKey: .firebaseHost)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(apnAuthKey, forKey: .apnAuthKey)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(xiaomiAppSecret, forKey: .xiaomiAppSecret)
        
        try container.encode(apnKeyId, forKey: .apnKeyId)
        
        try container.encode(disabledReason, forKey: .disabledReason)
        
        try container.encode(firebaseDataTemplate, forKey: .firebaseDataTemplate)
        
        try container.encode(apnHost, forKey: .apnHost)
        
        try container.encode(apnDevelopment, forKey: .apnDevelopment)
        
        try container.encode(apnTopic, forKey: .apnTopic)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(apnAuthType, forKey: .apnAuthType)
        
        try container.encode(xiaomiPackageName, forKey: .xiaomiPackageName)
        
        try container.encode(apnP12Cert, forKey: .apnP12Cert)
    }
}
