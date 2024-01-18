//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatApp: Codable, Hashable {
    public var pushNotifications: StreamChatPushNotificationFields
    
    public var webhookEvents: [String]
    
    public var asyncUrlEnrichEnabled: Bool
    
    public var callTypes: [String: RawJSON]
    
    public var geofences: [StreamChatGeofenceResponse?]?
    
    public var organization: String
    
    public var imageModerationEnabled: Bool
    
    public var name: String
    
    public var sqsKey: String
    
    public var agoraOptions: StreamChatConfig?
    
    public var beforeMessageSendHookUrl: String?
    
    public var policies: [String: RawJSON]
    
    public var suspended: Bool
    
    public var suspendedExplanation: String
    
    public var webhookUrl: String
    
    public var allowedFlagReasons: [String]?
    
    public var enforceUniqueUsernames: String
    
    public var revokeTokensIssuedBefore: Date?
    
    public var sqsUrl: String
    
    public var sqsSecret: String
    
    public var autoTranslationEnabled: Bool?
    
    public var campaignEnabled: Bool
    
    public var customActionHandlerUrl: String
    
    public var imageUploadConfig: StreamChatFileUploadConfig
    
    public var snsSecret: String
    
    public var fileUploadConfig: StreamChatFileUploadConfig
    
    public var grants: [String: RawJSON]
    
    public var permissionVersion: String
    
    public var snsKey: String
    
    public var multiTenantEnabled: Bool
    
    public var videoProvider: String
    
    public var channelConfigs: [String: RawJSON]
    
    public var disableAuthChecks: Bool
    
    public var disablePermissionsChecks: Bool
    
    public var hmsOptions: StreamChatConfig?
    
    public var snsTopicArn: String
    
    public var userSearchDisallowedRoles: [String]
    
    public var cdnExpirationSeconds: Int
    
    public var datadogInfo: StreamChatDataDogInfo?
    
    public var imageModerationLabels: [String]?
    
    public var remindersInterval: Int
    
    public init(pushNotifications: StreamChatPushNotificationFields, webhookEvents: [String], asyncUrlEnrichEnabled: Bool, callTypes: [String: RawJSON], geofences: [StreamChatGeofenceResponse?]?, organization: String, imageModerationEnabled: Bool, name: String, sqsKey: String, agoraOptions: StreamChatConfig?, beforeMessageSendHookUrl: String?, policies: [String: RawJSON], suspended: Bool, suspendedExplanation: String, webhookUrl: String, allowedFlagReasons: [String]?, enforceUniqueUsernames: String, revokeTokensIssuedBefore: Date?, sqsUrl: String, sqsSecret: String, autoTranslationEnabled: Bool?, campaignEnabled: Bool, customActionHandlerUrl: String, imageUploadConfig: StreamChatFileUploadConfig, snsSecret: String, fileUploadConfig: StreamChatFileUploadConfig, grants: [String: RawJSON], permissionVersion: String, snsKey: String, multiTenantEnabled: Bool, videoProvider: String, channelConfigs: [String: RawJSON], disableAuthChecks: Bool, disablePermissionsChecks: Bool, hmsOptions: StreamChatConfig?, snsTopicArn: String, userSearchDisallowedRoles: [String], cdnExpirationSeconds: Int, datadogInfo: StreamChatDataDogInfo?, imageModerationLabels: [String]?, remindersInterval: Int) {
        self.pushNotifications = pushNotifications
        
        self.webhookEvents = webhookEvents
        
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        
        self.callTypes = callTypes
        
        self.geofences = geofences
        
        self.organization = organization
        
        self.imageModerationEnabled = imageModerationEnabled
        
        self.name = name
        
        self.sqsKey = sqsKey
        
        self.agoraOptions = agoraOptions
        
        self.beforeMessageSendHookUrl = beforeMessageSendHookUrl
        
        self.policies = policies
        
        self.suspended = suspended
        
        self.suspendedExplanation = suspendedExplanation
        
        self.webhookUrl = webhookUrl
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.enforceUniqueUsernames = enforceUniqueUsernames
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.sqsUrl = sqsUrl
        
        self.sqsSecret = sqsSecret
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.campaignEnabled = campaignEnabled
        
        self.customActionHandlerUrl = customActionHandlerUrl
        
        self.imageUploadConfig = imageUploadConfig
        
        self.snsSecret = snsSecret
        
        self.fileUploadConfig = fileUploadConfig
        
        self.grants = grants
        
        self.permissionVersion = permissionVersion
        
        self.snsKey = snsKey
        
        self.multiTenantEnabled = multiTenantEnabled
        
        self.videoProvider = videoProvider
        
        self.channelConfigs = channelConfigs
        
        self.disableAuthChecks = disableAuthChecks
        
        self.disablePermissionsChecks = disablePermissionsChecks
        
        self.hmsOptions = hmsOptions
        
        self.snsTopicArn = snsTopicArn
        
        self.userSearchDisallowedRoles = userSearchDisallowedRoles
        
        self.cdnExpirationSeconds = cdnExpirationSeconds
        
        self.datadogInfo = datadogInfo
        
        self.imageModerationLabels = imageModerationLabels
        
        self.remindersInterval = remindersInterval
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pushNotifications = "push_notifications"
        
        case webhookEvents = "webhook_events"
        
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        
        case callTypes = "call_types"
        
        case geofences
        
        case organization
        
        case imageModerationEnabled = "image_moderation_enabled"
        
        case name
        
        case sqsKey = "sqs_key"
        
        case agoraOptions = "agora_options"
        
        case beforeMessageSendHookUrl = "before_message_send_hook_url"
        
        case policies
        
        case suspended
        
        case suspendedExplanation = "suspended_explanation"
        
        case webhookUrl = "webhook_url"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case enforceUniqueUsernames = "enforce_unique_usernames"
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case sqsUrl = "sqs_url"
        
        case sqsSecret = "sqs_secret"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case campaignEnabled = "campaign_enabled"
        
        case customActionHandlerUrl = "custom_action_handler_url"
        
        case imageUploadConfig = "image_upload_config"
        
        case snsSecret = "sns_secret"
        
        case fileUploadConfig = "file_upload_config"
        
        case grants
        
        case permissionVersion = "permission_version"
        
        case snsKey = "sns_key"
        
        case multiTenantEnabled = "multi_tenant_enabled"
        
        case videoProvider = "video_provider"
        
        case channelConfigs = "channel_configs"
        
        case disableAuthChecks = "disable_auth_checks"
        
        case disablePermissionsChecks = "disable_permissions_checks"
        
        case hmsOptions = "hms_options"
        
        case snsTopicArn = "sns_topic_arn"
        
        case userSearchDisallowedRoles = "user_search_disallowed_roles"
        
        case cdnExpirationSeconds = "cdn_expiration_seconds"
        
        case datadogInfo = "datadog_info"
        
        case imageModerationLabels = "image_moderation_labels"
        
        case remindersInterval = "reminders_interval"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(webhookEvents, forKey: .webhookEvents)
        
        try container.encode(asyncUrlEnrichEnabled, forKey: .asyncUrlEnrichEnabled)
        
        try container.encode(callTypes, forKey: .callTypes)
        
        try container.encode(geofences, forKey: .geofences)
        
        try container.encode(organization, forKey: .organization)
        
        try container.encode(imageModerationEnabled, forKey: .imageModerationEnabled)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(sqsKey, forKey: .sqsKey)
        
        try container.encode(agoraOptions, forKey: .agoraOptions)
        
        try container.encode(beforeMessageSendHookUrl, forKey: .beforeMessageSendHookUrl)
        
        try container.encode(policies, forKey: .policies)
        
        try container.encode(suspended, forKey: .suspended)
        
        try container.encode(suspendedExplanation, forKey: .suspendedExplanation)
        
        try container.encode(webhookUrl, forKey: .webhookUrl)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(enforceUniqueUsernames, forKey: .enforceUniqueUsernames)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(sqsUrl, forKey: .sqsUrl)
        
        try container.encode(sqsSecret, forKey: .sqsSecret)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(campaignEnabled, forKey: .campaignEnabled)
        
        try container.encode(customActionHandlerUrl, forKey: .customActionHandlerUrl)
        
        try container.encode(imageUploadConfig, forKey: .imageUploadConfig)
        
        try container.encode(snsSecret, forKey: .snsSecret)
        
        try container.encode(fileUploadConfig, forKey: .fileUploadConfig)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(permissionVersion, forKey: .permissionVersion)
        
        try container.encode(snsKey, forKey: .snsKey)
        
        try container.encode(multiTenantEnabled, forKey: .multiTenantEnabled)
        
        try container.encode(videoProvider, forKey: .videoProvider)
        
        try container.encode(channelConfigs, forKey: .channelConfigs)
        
        try container.encode(disableAuthChecks, forKey: .disableAuthChecks)
        
        try container.encode(disablePermissionsChecks, forKey: .disablePermissionsChecks)
        
        try container.encode(hmsOptions, forKey: .hmsOptions)
        
        try container.encode(snsTopicArn, forKey: .snsTopicArn)
        
        try container.encode(userSearchDisallowedRoles, forKey: .userSearchDisallowedRoles)
        
        try container.encode(cdnExpirationSeconds, forKey: .cdnExpirationSeconds)
        
        try container.encode(datadogInfo, forKey: .datadogInfo)
        
        try container.encode(imageModerationLabels, forKey: .imageModerationLabels)
        
        try container.encode(remindersInterval, forKey: .remindersInterval)
    }
}
