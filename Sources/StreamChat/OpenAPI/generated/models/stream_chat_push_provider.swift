//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPushProvider: Codable, Hashable {
    public var name: String
    
    public var apnKeyId: String?
    
    public var disabledAt: Date?
    
    public var firebaseCredentials: String?
    
    public var apnTopic: String?
    
    public var type: Int
    
    public var updatedAt: Date
    
    public var disabledReason: String?
    
    public var firebaseApnTemplate: String?
    
    public var firebaseNotificationTemplate: String?
    
    public var huaweiAppSecret: String?
    
    public var xiaomiPackageName: String?
    
    public var apnDevelopment: Bool?
    
    public var apnHost: String?
    
    public var apnP12Cert: String?
    
    public var createdAt: Date
    
    public var firebaseHost: String?
    
    public var xiaomiAppSecret: String?
    
    public var apnAuthKey: String?
    
    public var apnNotificationTemplate: String?
    
    public var description: String?
    
    public var firebaseDataTemplate: String?
    
    public var huaweiAppId: String?
    
    public var apnAuthType: String?
    
    public var apnTeamId: String?
    
    public var firebaseServerKey: String?
    
    public init(name: String, apnKeyId: String?, disabledAt: Date?, firebaseCredentials: String?, apnTopic: String?, type: Int, updatedAt: Date, disabledReason: String?, firebaseApnTemplate: String?, firebaseNotificationTemplate: String?, huaweiAppSecret: String?, xiaomiPackageName: String?, apnDevelopment: Bool?, apnHost: String?, apnP12Cert: String?, createdAt: Date, firebaseHost: String?, xiaomiAppSecret: String?, apnAuthKey: String?, apnNotificationTemplate: String?, description: String?, firebaseDataTemplate: String?, huaweiAppId: String?, apnAuthType: String?, apnTeamId: String?, firebaseServerKey: String?) {
        self.name = name
        
        self.apnKeyId = apnKeyId
        
        self.disabledAt = disabledAt
        
        self.firebaseCredentials = firebaseCredentials
        
        self.apnTopic = apnTopic
        
        self.type = type
        
        self.updatedAt = updatedAt
        
        self.disabledReason = disabledReason
        
        self.firebaseApnTemplate = firebaseApnTemplate
        
        self.firebaseNotificationTemplate = firebaseNotificationTemplate
        
        self.huaweiAppSecret = huaweiAppSecret
        
        self.xiaomiPackageName = xiaomiPackageName
        
        self.apnDevelopment = apnDevelopment
        
        self.apnHost = apnHost
        
        self.apnP12Cert = apnP12Cert
        
        self.createdAt = createdAt
        
        self.firebaseHost = firebaseHost
        
        self.xiaomiAppSecret = xiaomiAppSecret
        
        self.apnAuthKey = apnAuthKey
        
        self.apnNotificationTemplate = apnNotificationTemplate
        
        self.description = description
        
        self.firebaseDataTemplate = firebaseDataTemplate
        
        self.huaweiAppId = huaweiAppId
        
        self.apnAuthType = apnAuthType
        
        self.apnTeamId = apnTeamId
        
        self.firebaseServerKey = firebaseServerKey
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case apnKeyId = "apn_key_id"
        
        case disabledAt = "disabled_at"
        
        case firebaseCredentials = "firebase_credentials"
        
        case apnTopic = "apn_topic"
        
        case type
        
        case updatedAt = "updated_at"
        
        case disabledReason = "disabled_reason"
        
        case firebaseApnTemplate = "firebase_apn_template"
        
        case firebaseNotificationTemplate = "firebase_notification_template"
        
        case huaweiAppSecret = "huawei_app_secret"
        
        case xiaomiPackageName = "xiaomi_package_name"
        
        case apnDevelopment = "apn_development"
        
        case apnHost = "apn_host"
        
        case apnP12Cert = "apn_p12_cert"
        
        case createdAt = "created_at"
        
        case firebaseHost = "firebase_host"
        
        case xiaomiAppSecret = "xiaomi_app_secret"
        
        case apnAuthKey = "apn_auth_key"
        
        case apnNotificationTemplate = "apn_notification_template"
        
        case description
        
        case firebaseDataTemplate = "firebase_data_template"
        
        case huaweiAppId = "huawei_app_id"
        
        case apnAuthType = "apn_auth_type"
        
        case apnTeamId = "apn_team_id"
        
        case firebaseServerKey = "firebase_server_key"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(apnKeyId, forKey: .apnKeyId)
        
        try container.encode(disabledAt, forKey: .disabledAt)
        
        try container.encode(firebaseCredentials, forKey: .firebaseCredentials)
        
        try container.encode(apnTopic, forKey: .apnTopic)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(disabledReason, forKey: .disabledReason)
        
        try container.encode(firebaseApnTemplate, forKey: .firebaseApnTemplate)
        
        try container.encode(firebaseNotificationTemplate, forKey: .firebaseNotificationTemplate)
        
        try container.encode(huaweiAppSecret, forKey: .huaweiAppSecret)
        
        try container.encode(xiaomiPackageName, forKey: .xiaomiPackageName)
        
        try container.encode(apnDevelopment, forKey: .apnDevelopment)
        
        try container.encode(apnHost, forKey: .apnHost)
        
        try container.encode(apnP12Cert, forKey: .apnP12Cert)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(firebaseHost, forKey: .firebaseHost)
        
        try container.encode(xiaomiAppSecret, forKey: .xiaomiAppSecret)
        
        try container.encode(apnAuthKey, forKey: .apnAuthKey)
        
        try container.encode(apnNotificationTemplate, forKey: .apnNotificationTemplate)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(firebaseDataTemplate, forKey: .firebaseDataTemplate)
        
        try container.encode(huaweiAppId, forKey: .huaweiAppId)
        
        try container.encode(apnAuthType, forKey: .apnAuthType)
        
        try container.encode(apnTeamId, forKey: .apnTeamId)
        
        try container.encode(firebaseServerKey, forKey: .firebaseServerKey)
    }
}
