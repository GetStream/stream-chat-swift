//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PushProvider: Codable, Hashable {
    public var createdAt: Date
    public var name: String
    public var type: Int
    public var updatedAt: Date
    public var apnAuthKey: String? = nil
    public var apnAuthType: String? = nil
    public var apnDevelopment: Bool? = nil
    public var apnHost: String? = nil
    public var apnKeyId: String? = nil
    public var apnNotificationTemplate: String? = nil
    public var apnP12Cert: String? = nil
    public var apnTeamId: String? = nil
    public var apnTopic: String? = nil
    public var description: String? = nil
    public var disabledAt: Date? = nil
    public var disabledReason: String? = nil
    public var firebaseApnTemplate: String? = nil
    public var firebaseCredentials: String? = nil
    public var firebaseDataTemplate: String? = nil
    public var firebaseHost: String? = nil
    public var firebaseNotificationTemplate: String? = nil
    public var firebaseServerKey: String? = nil
    public var huaweiAppId: String? = nil
    public var huaweiAppSecret: String? = nil
    public var xiaomiAppSecret: String? = nil
    public var xiaomiPackageName: String? = nil

    public init(createdAt: Date, name: String, type: Int, updatedAt: Date, apnAuthKey: String? = nil, apnAuthType: String? = nil, apnDevelopment: Bool? = nil, apnHost: String? = nil, apnKeyId: String? = nil, apnNotificationTemplate: String? = nil, apnP12Cert: String? = nil, apnTeamId: String? = nil, apnTopic: String? = nil, description: String? = nil, disabledAt: Date? = nil, disabledReason: String? = nil, firebaseApnTemplate: String? = nil, firebaseCredentials: String? = nil, firebaseDataTemplate: String? = nil, firebaseHost: String? = nil, firebaseNotificationTemplate: String? = nil, firebaseServerKey: String? = nil, huaweiAppId: String? = nil, huaweiAppSecret: String? = nil, xiaomiAppSecret: String? = nil, xiaomiPackageName: String? = nil) {
        self.createdAt = createdAt
        self.name = name
        self.type = type
        self.updatedAt = updatedAt
        self.apnAuthKey = apnAuthKey
        self.apnAuthType = apnAuthType
        self.apnDevelopment = apnDevelopment
        self.apnHost = apnHost
        self.apnKeyId = apnKeyId
        self.apnNotificationTemplate = apnNotificationTemplate
        self.apnP12Cert = apnP12Cert
        self.apnTeamId = apnTeamId
        self.apnTopic = apnTopic
        self.description = description
        self.disabledAt = disabledAt
        self.disabledReason = disabledReason
        self.firebaseApnTemplate = firebaseApnTemplate
        self.firebaseCredentials = firebaseCredentials
        self.firebaseDataTemplate = firebaseDataTemplate
        self.firebaseHost = firebaseHost
        self.firebaseNotificationTemplate = firebaseNotificationTemplate
        self.firebaseServerKey = firebaseServerKey
        self.huaweiAppId = huaweiAppId
        self.huaweiAppSecret = huaweiAppSecret
        self.xiaomiAppSecret = xiaomiAppSecret
        self.xiaomiPackageName = xiaomiPackageName
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case name
        case type
        case updatedAt = "updated_at"
        case apnAuthKey = "apn_auth_key"
        case apnAuthType = "apn_auth_type"
        case apnDevelopment = "apn_development"
        case apnHost = "apn_host"
        case apnKeyId = "apn_key_id"
        case apnNotificationTemplate = "apn_notification_template"
        case apnP12Cert = "apn_p12_cert"
        case apnTeamId = "apn_team_id"
        case apnTopic = "apn_topic"
        case description
        case disabledAt = "disabled_at"
        case disabledReason = "disabled_reason"
        case firebaseApnTemplate = "firebase_apn_template"
        case firebaseCredentials = "firebase_credentials"
        case firebaseDataTemplate = "firebase_data_template"
        case firebaseHost = "firebase_host"
        case firebaseNotificationTemplate = "firebase_notification_template"
        case firebaseServerKey = "firebase_server_key"
        case huaweiAppId = "huawei_app_id"
        case huaweiAppSecret = "huawei_app_secret"
        case xiaomiAppSecret = "xiaomi_app_secret"
        case xiaomiPackageName = "xiaomi_package_name"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(apnAuthKey, forKey: .apnAuthKey)
        try container.encode(apnAuthType, forKey: .apnAuthType)
        try container.encode(apnDevelopment, forKey: .apnDevelopment)
        try container.encode(apnHost, forKey: .apnHost)
        try container.encode(apnKeyId, forKey: .apnKeyId)
        try container.encode(apnNotificationTemplate, forKey: .apnNotificationTemplate)
        try container.encode(apnP12Cert, forKey: .apnP12Cert)
        try container.encode(apnTeamId, forKey: .apnTeamId)
        try container.encode(apnTopic, forKey: .apnTopic)
        try container.encode(description, forKey: .description)
        try container.encode(disabledAt, forKey: .disabledAt)
        try container.encode(disabledReason, forKey: .disabledReason)
        try container.encode(firebaseApnTemplate, forKey: .firebaseApnTemplate)
        try container.encode(firebaseCredentials, forKey: .firebaseCredentials)
        try container.encode(firebaseDataTemplate, forKey: .firebaseDataTemplate)
        try container.encode(firebaseHost, forKey: .firebaseHost)
        try container.encode(firebaseNotificationTemplate, forKey: .firebaseNotificationTemplate)
        try container.encode(firebaseServerKey, forKey: .firebaseServerKey)
        try container.encode(huaweiAppId, forKey: .huaweiAppId)
        try container.encode(huaweiAppSecret, forKey: .huaweiAppSecret)
        try container.encode(xiaomiAppSecret, forKey: .xiaomiAppSecret)
        try container.encode(xiaomiPackageName, forKey: .xiaomiPackageName)
    }
}
