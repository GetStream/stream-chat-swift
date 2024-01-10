//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatApp: Codable, Hashable {
    public var asyncUrlEnrichEnabled: Bool
    
    public var imageUploadConfig: StreamChatFileUploadConfig
    
    public var multiTenantEnabled: Bool
    
    public var remindersInterval: Int
    
    public var agoraOptions: StreamChatConfig?
    
    public var policies: [String: RawJSON]
    
    public var sqsSecret: String
    
    public var webhookUrl: String
    
    public var beforeMessageSendHookUrl: String?
    
    public var campaignEnabled: Bool
    
    public var snsSecret: String
    
    public var suspended: Bool
    
    public var disableAuthChecks: Bool
    
    public var sqsUrl: String
    
    public var webhookEvents: [String]
    
    public var imageModerationLabels: [String]?
    
    public var permissionVersion: String
    
    public var snsKey: String
    
    public var videoProvider: String
    
    public var channelConfigs: [String: RawJSON]
    
    public var customActionHandlerUrl: String
    
    public var grants: [String: RawJSON]
    
    public var imageModerationEnabled: Bool
    
    public var sqsKey: String
    
    public var suspendedExplanation: String
    
    public var autoTranslationEnabled: Bool?
    
    public var callTypes: [String: RawJSON]
    
    public var fileUploadConfig: StreamChatFileUploadConfig
    
    public var pushNotifications: StreamChatPushNotificationFields
    
    public var geofences: [StreamChatGeofenceResponse?]?
    
    public var hmsOptions: StreamChatConfig?
    
    public var snsTopicArn: String
    
    public var userSearchDisallowedRoles: [String]
    
    public var enforceUniqueUsernames: String
    
    public var name: String
    
    public var organization: String
    
    public var revokeTokensIssuedBefore: String?
    
    public var allowedFlagReasons: [String]?
    
    public var cdnExpirationSeconds: Int
    
    public var datadogInfo: StreamChatDataDogInfo?
    
    public var disablePermissionsChecks: Bool
    
    public init(asyncUrlEnrichEnabled: Bool, imageUploadConfig: StreamChatFileUploadConfig, multiTenantEnabled: Bool, remindersInterval: Int, agoraOptions: StreamChatConfig?, policies: [String: RawJSON], sqsSecret: String, webhookUrl: String, beforeMessageSendHookUrl: String?, campaignEnabled: Bool, snsSecret: String, suspended: Bool, disableAuthChecks: Bool, sqsUrl: String, webhookEvents: [String], imageModerationLabels: [String]?, permissionVersion: String, snsKey: String, videoProvider: String, channelConfigs: [String: RawJSON], customActionHandlerUrl: String, grants: [String: RawJSON], imageModerationEnabled: Bool, sqsKey: String, suspendedExplanation: String, autoTranslationEnabled: Bool?, callTypes: [String: RawJSON], fileUploadConfig: StreamChatFileUploadConfig, pushNotifications: StreamChatPushNotificationFields, geofences: [StreamChatGeofenceResponse?]?, hmsOptions: StreamChatConfig?, snsTopicArn: String, userSearchDisallowedRoles: [String], enforceUniqueUsernames: String, name: String, organization: String, revokeTokensIssuedBefore: String?, allowedFlagReasons: [String]?, cdnExpirationSeconds: Int, datadogInfo: StreamChatDataDogInfo?, disablePermissionsChecks: Bool) {
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        
        self.imageUploadConfig = imageUploadConfig
        
        self.multiTenantEnabled = multiTenantEnabled
        
        self.remindersInterval = remindersInterval
        
        self.agoraOptions = agoraOptions
        
        self.policies = policies
        
        self.sqsSecret = sqsSecret
        
        self.webhookUrl = webhookUrl
        
        self.beforeMessageSendHookUrl = beforeMessageSendHookUrl
        
        self.campaignEnabled = campaignEnabled
        
        self.snsSecret = snsSecret
        
        self.suspended = suspended
        
        self.disableAuthChecks = disableAuthChecks
        
        self.sqsUrl = sqsUrl
        
        self.webhookEvents = webhookEvents
        
        self.imageModerationLabels = imageModerationLabels
        
        self.permissionVersion = permissionVersion
        
        self.snsKey = snsKey
        
        self.videoProvider = videoProvider
        
        self.channelConfigs = channelConfigs
        
        self.customActionHandlerUrl = customActionHandlerUrl
        
        self.grants = grants
        
        self.imageModerationEnabled = imageModerationEnabled
        
        self.sqsKey = sqsKey
        
        self.suspendedExplanation = suspendedExplanation
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.callTypes = callTypes
        
        self.fileUploadConfig = fileUploadConfig
        
        self.pushNotifications = pushNotifications
        
        self.geofences = geofences
        
        self.hmsOptions = hmsOptions
        
        self.snsTopicArn = snsTopicArn
        
        self.userSearchDisallowedRoles = userSearchDisallowedRoles
        
        self.enforceUniqueUsernames = enforceUniqueUsernames
        
        self.name = name
        
        self.organization = organization
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.cdnExpirationSeconds = cdnExpirationSeconds
        
        self.datadogInfo = datadogInfo
        
        self.disablePermissionsChecks = disablePermissionsChecks
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        
        case imageUploadConfig = "image_upload_config"
        
        case multiTenantEnabled = "multi_tenant_enabled"
        
        case remindersInterval = "reminders_interval"
        
        case agoraOptions = "agora_options"
        
        case policies
        
        case sqsSecret = "sqs_secret"
        
        case webhookUrl = "webhook_url"
        
        case beforeMessageSendHookUrl = "before_message_send_hook_url"
        
        case campaignEnabled = "campaign_enabled"
        
        case snsSecret = "sns_secret"
        
        case suspended
        
        case disableAuthChecks = "disable_auth_checks"
        
        case sqsUrl = "sqs_url"
        
        case webhookEvents = "webhook_events"
        
        case imageModerationLabels = "image_moderation_labels"
        
        case permissionVersion = "permission_version"
        
        case snsKey = "sns_key"
        
        case videoProvider = "video_provider"
        
        case channelConfigs = "channel_configs"
        
        case customActionHandlerUrl = "custom_action_handler_url"
        
        case grants
        
        case imageModerationEnabled = "image_moderation_enabled"
        
        case sqsKey = "sqs_key"
        
        case suspendedExplanation = "suspended_explanation"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case callTypes = "call_types"
        
        case fileUploadConfig = "file_upload_config"
        
        case pushNotifications = "push_notifications"
        
        case geofences
        
        case hmsOptions = "hms_options"
        
        case snsTopicArn = "sns_topic_arn"
        
        case userSearchDisallowedRoles = "user_search_disallowed_roles"
        
        case enforceUniqueUsernames = "enforce_unique_usernames"
        
        case name
        
        case organization
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case cdnExpirationSeconds = "cdn_expiration_seconds"
        
        case datadogInfo = "datadog_info"
        
        case disablePermissionsChecks = "disable_permissions_checks"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(asyncUrlEnrichEnabled, forKey: .asyncUrlEnrichEnabled)
        
        try container.encode(imageUploadConfig, forKey: .imageUploadConfig)
        
        try container.encode(multiTenantEnabled, forKey: .multiTenantEnabled)
        
        try container.encode(remindersInterval, forKey: .remindersInterval)
        
        try container.encode(agoraOptions, forKey: .agoraOptions)
        
        try container.encode(policies, forKey: .policies)
        
        try container.encode(sqsSecret, forKey: .sqsSecret)
        
        try container.encode(webhookUrl, forKey: .webhookUrl)
        
        try container.encode(beforeMessageSendHookUrl, forKey: .beforeMessageSendHookUrl)
        
        try container.encode(campaignEnabled, forKey: .campaignEnabled)
        
        try container.encode(snsSecret, forKey: .snsSecret)
        
        try container.encode(suspended, forKey: .suspended)
        
        try container.encode(disableAuthChecks, forKey: .disableAuthChecks)
        
        try container.encode(sqsUrl, forKey: .sqsUrl)
        
        try container.encode(webhookEvents, forKey: .webhookEvents)
        
        try container.encode(imageModerationLabels, forKey: .imageModerationLabels)
        
        try container.encode(permissionVersion, forKey: .permissionVersion)
        
        try container.encode(snsKey, forKey: .snsKey)
        
        try container.encode(videoProvider, forKey: .videoProvider)
        
        try container.encode(channelConfigs, forKey: .channelConfigs)
        
        try container.encode(customActionHandlerUrl, forKey: .customActionHandlerUrl)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(imageModerationEnabled, forKey: .imageModerationEnabled)
        
        try container.encode(sqsKey, forKey: .sqsKey)
        
        try container.encode(suspendedExplanation, forKey: .suspendedExplanation)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(callTypes, forKey: .callTypes)
        
        try container.encode(fileUploadConfig, forKey: .fileUploadConfig)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(geofences, forKey: .geofences)
        
        try container.encode(hmsOptions, forKey: .hmsOptions)
        
        try container.encode(snsTopicArn, forKey: .snsTopicArn)
        
        try container.encode(userSearchDisallowedRoles, forKey: .userSearchDisallowedRoles)
        
        try container.encode(enforceUniqueUsernames, forKey: .enforceUniqueUsernames)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(organization, forKey: .organization)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(cdnExpirationSeconds, forKey: .cdnExpirationSeconds)
        
        try container.encode(datadogInfo, forKey: .datadogInfo)
        
        try container.encode(disablePermissionsChecks, forKey: .disablePermissionsChecks)
    }
}
