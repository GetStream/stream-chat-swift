//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatApp: Codable, Hashable {
    public var agoraOptions: StreamChatConfig?
    
    public var campaignEnabled: Bool
    
    public var videoProvider: String
    
    public var callTypes: [String: RawJSON]
    
    public var userSearchDisallowedRoles: [String]
    
    public var grants: [String: RawJSON]
    
    public var imageModerationEnabled: Bool
    
    public var imageModerationLabels: [String]?
    
    public var sqsUrl: String
    
    public var autoTranslationEnabled: Bool?
    
    public var beforeMessageSendHookUrl: String?
    
    public var channelConfigs: [String: RawJSON]
    
    public var datadogInfo: StreamChatDataDogInfo?
    
    public var suspendedExplanation: String
    
    public var webhookEvents: [String]
    
    public var sqsKey: String
    
    public var disablePermissionsChecks: Bool
    
    public var enforceUniqueUsernames: String
    
    public var name: String
    
    public var snsTopicArn: String
    
    public var snsKey: String
    
    public var sqsSecret: String
    
    public var suspended: Bool
    
    public var webhookUrl: String
    
    public var disableAuthChecks: Bool
    
    public var imageUploadConfig: StreamChatFileUploadConfig
    
    public var policies: [String: RawJSON]
    
    public var remindersInterval: Int
    
    public var pushNotifications: StreamChatPushNotificationFields
    
    public var revokeTokensIssuedBefore: Date?
    
    public var snsSecret: String
    
    public var allowedFlagReasons: [String]?
    
    public var asyncUrlEnrichEnabled: Bool
    
    public var hmsOptions: StreamChatConfig?
    
    public var permissionVersion: String
    
    public var multiTenantEnabled: Bool
    
    public var organization: String
    
    public var cdnExpirationSeconds: Int
    
    public var customActionHandlerUrl: String
    
    public var fileUploadConfig: StreamChatFileUploadConfig
    
    public var geofences: [StreamChatGeofenceResponse?]?
    
    public init(agoraOptions: StreamChatConfig?, campaignEnabled: Bool, videoProvider: String, callTypes: [String: RawJSON], userSearchDisallowedRoles: [String], grants: [String: RawJSON], imageModerationEnabled: Bool, imageModerationLabels: [String]?, sqsUrl: String, autoTranslationEnabled: Bool?, beforeMessageSendHookUrl: String?, channelConfigs: [String: RawJSON], datadogInfo: StreamChatDataDogInfo?, suspendedExplanation: String, webhookEvents: [String], sqsKey: String, disablePermissionsChecks: Bool, enforceUniqueUsernames: String, name: String, snsTopicArn: String, snsKey: String, sqsSecret: String, suspended: Bool, webhookUrl: String, disableAuthChecks: Bool, imageUploadConfig: StreamChatFileUploadConfig, policies: [String: RawJSON], remindersInterval: Int, pushNotifications: StreamChatPushNotificationFields, revokeTokensIssuedBefore: Date?, snsSecret: String, allowedFlagReasons: [String]?, asyncUrlEnrichEnabled: Bool, hmsOptions: StreamChatConfig?, permissionVersion: String, multiTenantEnabled: Bool, organization: String, cdnExpirationSeconds: Int, customActionHandlerUrl: String, fileUploadConfig: StreamChatFileUploadConfig, geofences: [StreamChatGeofenceResponse?]?) {
        self.agoraOptions = agoraOptions
        
        self.campaignEnabled = campaignEnabled
        
        self.videoProvider = videoProvider
        
        self.callTypes = callTypes
        
        self.userSearchDisallowedRoles = userSearchDisallowedRoles
        
        self.grants = grants
        
        self.imageModerationEnabled = imageModerationEnabled
        
        self.imageModerationLabels = imageModerationLabels
        
        self.sqsUrl = sqsUrl
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.beforeMessageSendHookUrl = beforeMessageSendHookUrl
        
        self.channelConfigs = channelConfigs
        
        self.datadogInfo = datadogInfo
        
        self.suspendedExplanation = suspendedExplanation
        
        self.webhookEvents = webhookEvents
        
        self.sqsKey = sqsKey
        
        self.disablePermissionsChecks = disablePermissionsChecks
        
        self.enforceUniqueUsernames = enforceUniqueUsernames
        
        self.name = name
        
        self.snsTopicArn = snsTopicArn
        
        self.snsKey = snsKey
        
        self.sqsSecret = sqsSecret
        
        self.suspended = suspended
        
        self.webhookUrl = webhookUrl
        
        self.disableAuthChecks = disableAuthChecks
        
        self.imageUploadConfig = imageUploadConfig
        
        self.policies = policies
        
        self.remindersInterval = remindersInterval
        
        self.pushNotifications = pushNotifications
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.snsSecret = snsSecret
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        
        self.hmsOptions = hmsOptions
        
        self.permissionVersion = permissionVersion
        
        self.multiTenantEnabled = multiTenantEnabled
        
        self.organization = organization
        
        self.cdnExpirationSeconds = cdnExpirationSeconds
        
        self.customActionHandlerUrl = customActionHandlerUrl
        
        self.fileUploadConfig = fileUploadConfig
        
        self.geofences = geofences
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case agoraOptions = "agora_options"
        
        case campaignEnabled = "campaign_enabled"
        
        case videoProvider = "video_provider"
        
        case callTypes = "call_types"
        
        case userSearchDisallowedRoles = "user_search_disallowed_roles"
        
        case grants
        
        case imageModerationEnabled = "image_moderation_enabled"
        
        case imageModerationLabels = "image_moderation_labels"
        
        case sqsUrl = "sqs_url"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case beforeMessageSendHookUrl = "before_message_send_hook_url"
        
        case channelConfigs = "channel_configs"
        
        case datadogInfo = "datadog_info"
        
        case suspendedExplanation = "suspended_explanation"
        
        case webhookEvents = "webhook_events"
        
        case sqsKey = "sqs_key"
        
        case disablePermissionsChecks = "disable_permissions_checks"
        
        case enforceUniqueUsernames = "enforce_unique_usernames"
        
        case name
        
        case snsTopicArn = "sns_topic_arn"
        
        case snsKey = "sns_key"
        
        case sqsSecret = "sqs_secret"
        
        case suspended
        
        case webhookUrl = "webhook_url"
        
        case disableAuthChecks = "disable_auth_checks"
        
        case imageUploadConfig = "image_upload_config"
        
        case policies
        
        case remindersInterval = "reminders_interval"
        
        case pushNotifications = "push_notifications"
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case snsSecret = "sns_secret"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        
        case hmsOptions = "hms_options"
        
        case permissionVersion = "permission_version"
        
        case multiTenantEnabled = "multi_tenant_enabled"
        
        case organization
        
        case cdnExpirationSeconds = "cdn_expiration_seconds"
        
        case customActionHandlerUrl = "custom_action_handler_url"
        
        case fileUploadConfig = "file_upload_config"
        
        case geofences
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(agoraOptions, forKey: .agoraOptions)
        
        try container.encode(campaignEnabled, forKey: .campaignEnabled)
        
        try container.encode(videoProvider, forKey: .videoProvider)
        
        try container.encode(callTypes, forKey: .callTypes)
        
        try container.encode(userSearchDisallowedRoles, forKey: .userSearchDisallowedRoles)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(imageModerationEnabled, forKey: .imageModerationEnabled)
        
        try container.encode(imageModerationLabels, forKey: .imageModerationLabels)
        
        try container.encode(sqsUrl, forKey: .sqsUrl)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(beforeMessageSendHookUrl, forKey: .beforeMessageSendHookUrl)
        
        try container.encode(channelConfigs, forKey: .channelConfigs)
        
        try container.encode(datadogInfo, forKey: .datadogInfo)
        
        try container.encode(suspendedExplanation, forKey: .suspendedExplanation)
        
        try container.encode(webhookEvents, forKey: .webhookEvents)
        
        try container.encode(sqsKey, forKey: .sqsKey)
        
        try container.encode(disablePermissionsChecks, forKey: .disablePermissionsChecks)
        
        try container.encode(enforceUniqueUsernames, forKey: .enforceUniqueUsernames)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(snsTopicArn, forKey: .snsTopicArn)
        
        try container.encode(snsKey, forKey: .snsKey)
        
        try container.encode(sqsSecret, forKey: .sqsSecret)
        
        try container.encode(suspended, forKey: .suspended)
        
        try container.encode(webhookUrl, forKey: .webhookUrl)
        
        try container.encode(disableAuthChecks, forKey: .disableAuthChecks)
        
        try container.encode(imageUploadConfig, forKey: .imageUploadConfig)
        
        try container.encode(policies, forKey: .policies)
        
        try container.encode(remindersInterval, forKey: .remindersInterval)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(snsSecret, forKey: .snsSecret)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(asyncUrlEnrichEnabled, forKey: .asyncUrlEnrichEnabled)
        
        try container.encode(hmsOptions, forKey: .hmsOptions)
        
        try container.encode(permissionVersion, forKey: .permissionVersion)
        
        try container.encode(multiTenantEnabled, forKey: .multiTenantEnabled)
        
        try container.encode(organization, forKey: .organization)
        
        try container.encode(cdnExpirationSeconds, forKey: .cdnExpirationSeconds)
        
        try container.encode(customActionHandlerUrl, forKey: .customActionHandlerUrl)
        
        try container.encode(fileUploadConfig, forKey: .fileUploadConfig)
        
        try container.encode(geofences, forKey: .geofences)
    }
}
