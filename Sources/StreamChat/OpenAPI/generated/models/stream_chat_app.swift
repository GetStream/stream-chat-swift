//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatApp: Codable, Hashable {
    public var callTypes: [String: RawJSON]
    
    public var campaignEnabled: Bool
    
    public var snsSecret: String
    
    public var sqsSecret: String
    
    public var videoProvider: String
    
    public var cdnExpirationSeconds: Int
    
    public var sqsUrl: String
    
    public var userSearchDisallowedRoles: [String]
    
    public var webhookEvents: [String]
    
    public var webhookUrl: String
    
    public var customActionHandlerUrl: String
    
    public var grants: [String: RawJSON]
    
    public var hmsOptions: StreamChatConfig?
    
    public var imageUploadConfig: StreamChatFileUploadConfig
    
    public var suspendedExplanation: String
    
    public var autoTranslationEnabled: Bool?
    
    public var beforeMessageSendHookUrl: String?
    
    public var channelConfigs: [String: RawJSON]
    
    public var geofences: [StreamChatGeofenceResponse?]?
    
    public var permissionVersion: String
    
    public var remindersInterval: Int
    
    public var enforceUniqueUsernames: String
    
    public var fileUploadConfig: StreamChatFileUploadConfig
    
    public var revokeTokensIssuedBefore: String?
    
    public var snsTopicArn: String
    
    public var disablePermissionsChecks: Bool
    
    public var imageModerationLabels: [String]?
    
    public var organization: String
    
    public var sqsKey: String
    
    public var suspended: Bool
    
    public var datadogInfo: StreamChatDataDogInfo?
    
    public var imageModerationEnabled: Bool
    
    public var name: String
    
    public var snsKey: String
    
    public var pushNotifications: StreamChatPushNotificationFields
    
    public var agoraOptions: StreamChatConfig?
    
    public var allowedFlagReasons: [String]?
    
    public var asyncUrlEnrichEnabled: Bool
    
    public var disableAuthChecks: Bool
    
    public var multiTenantEnabled: Bool
    
    public var policies: [String: RawJSON]
    
    public init(callTypes: [String: RawJSON], campaignEnabled: Bool, snsSecret: String, sqsSecret: String, videoProvider: String, cdnExpirationSeconds: Int, sqsUrl: String, userSearchDisallowedRoles: [String], webhookEvents: [String], webhookUrl: String, customActionHandlerUrl: String, grants: [String: RawJSON], hmsOptions: StreamChatConfig?, imageUploadConfig: StreamChatFileUploadConfig, suspendedExplanation: String, autoTranslationEnabled: Bool?, beforeMessageSendHookUrl: String?, channelConfigs: [String: RawJSON], geofences: [StreamChatGeofenceResponse?]?, permissionVersion: String, remindersInterval: Int, enforceUniqueUsernames: String, fileUploadConfig: StreamChatFileUploadConfig, revokeTokensIssuedBefore: String?, snsTopicArn: String, disablePermissionsChecks: Bool, imageModerationLabels: [String]?, organization: String, sqsKey: String, suspended: Bool, datadogInfo: StreamChatDataDogInfo?, imageModerationEnabled: Bool, name: String, snsKey: String, pushNotifications: StreamChatPushNotificationFields, agoraOptions: StreamChatConfig?, allowedFlagReasons: [String]?, asyncUrlEnrichEnabled: Bool, disableAuthChecks: Bool, multiTenantEnabled: Bool, policies: [String: RawJSON]) {
        self.callTypes = callTypes
        
        self.campaignEnabled = campaignEnabled
        
        self.snsSecret = snsSecret
        
        self.sqsSecret = sqsSecret
        
        self.videoProvider = videoProvider
        
        self.cdnExpirationSeconds = cdnExpirationSeconds
        
        self.sqsUrl = sqsUrl
        
        self.userSearchDisallowedRoles = userSearchDisallowedRoles
        
        self.webhookEvents = webhookEvents
        
        self.webhookUrl = webhookUrl
        
        self.customActionHandlerUrl = customActionHandlerUrl
        
        self.grants = grants
        
        self.hmsOptions = hmsOptions
        
        self.imageUploadConfig = imageUploadConfig
        
        self.suspendedExplanation = suspendedExplanation
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.beforeMessageSendHookUrl = beforeMessageSendHookUrl
        
        self.channelConfigs = channelConfigs
        
        self.geofences = geofences
        
        self.permissionVersion = permissionVersion
        
        self.remindersInterval = remindersInterval
        
        self.enforceUniqueUsernames = enforceUniqueUsernames
        
        self.fileUploadConfig = fileUploadConfig
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.snsTopicArn = snsTopicArn
        
        self.disablePermissionsChecks = disablePermissionsChecks
        
        self.imageModerationLabels = imageModerationLabels
        
        self.organization = organization
        
        self.sqsKey = sqsKey
        
        self.suspended = suspended
        
        self.datadogInfo = datadogInfo
        
        self.imageModerationEnabled = imageModerationEnabled
        
        self.name = name
        
        self.snsKey = snsKey
        
        self.pushNotifications = pushNotifications
        
        self.agoraOptions = agoraOptions
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        
        self.disableAuthChecks = disableAuthChecks
        
        self.multiTenantEnabled = multiTenantEnabled
        
        self.policies = policies
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callTypes = "call_types"
        
        case campaignEnabled = "campaign_enabled"
        
        case snsSecret = "sns_secret"
        
        case sqsSecret = "sqs_secret"
        
        case videoProvider = "video_provider"
        
        case cdnExpirationSeconds = "cdn_expiration_seconds"
        
        case sqsUrl = "sqs_url"
        
        case userSearchDisallowedRoles = "user_search_disallowed_roles"
        
        case webhookEvents = "webhook_events"
        
        case webhookUrl = "webhook_url"
        
        case customActionHandlerUrl = "custom_action_handler_url"
        
        case grants
        
        case hmsOptions = "hms_options"
        
        case imageUploadConfig = "image_upload_config"
        
        case suspendedExplanation = "suspended_explanation"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case beforeMessageSendHookUrl = "before_message_send_hook_url"
        
        case channelConfigs = "channel_configs"
        
        case geofences
        
        case permissionVersion = "permission_version"
        
        case remindersInterval = "reminders_interval"
        
        case enforceUniqueUsernames = "enforce_unique_usernames"
        
        case fileUploadConfig = "file_upload_config"
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case snsTopicArn = "sns_topic_arn"
        
        case disablePermissionsChecks = "disable_permissions_checks"
        
        case imageModerationLabels = "image_moderation_labels"
        
        case organization
        
        case sqsKey = "sqs_key"
        
        case suspended
        
        case datadogInfo = "datadog_info"
        
        case imageModerationEnabled = "image_moderation_enabled"
        
        case name
        
        case snsKey = "sns_key"
        
        case pushNotifications = "push_notifications"
        
        case agoraOptions = "agora_options"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        
        case disableAuthChecks = "disable_auth_checks"
        
        case multiTenantEnabled = "multi_tenant_enabled"
        
        case policies
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callTypes, forKey: .callTypes)
        
        try container.encode(campaignEnabled, forKey: .campaignEnabled)
        
        try container.encode(snsSecret, forKey: .snsSecret)
        
        try container.encode(sqsSecret, forKey: .sqsSecret)
        
        try container.encode(videoProvider, forKey: .videoProvider)
        
        try container.encode(cdnExpirationSeconds, forKey: .cdnExpirationSeconds)
        
        try container.encode(sqsUrl, forKey: .sqsUrl)
        
        try container.encode(userSearchDisallowedRoles, forKey: .userSearchDisallowedRoles)
        
        try container.encode(webhookEvents, forKey: .webhookEvents)
        
        try container.encode(webhookUrl, forKey: .webhookUrl)
        
        try container.encode(customActionHandlerUrl, forKey: .customActionHandlerUrl)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(hmsOptions, forKey: .hmsOptions)
        
        try container.encode(imageUploadConfig, forKey: .imageUploadConfig)
        
        try container.encode(suspendedExplanation, forKey: .suspendedExplanation)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(beforeMessageSendHookUrl, forKey: .beforeMessageSendHookUrl)
        
        try container.encode(channelConfigs, forKey: .channelConfigs)
        
        try container.encode(geofences, forKey: .geofences)
        
        try container.encode(permissionVersion, forKey: .permissionVersion)
        
        try container.encode(remindersInterval, forKey: .remindersInterval)
        
        try container.encode(enforceUniqueUsernames, forKey: .enforceUniqueUsernames)
        
        try container.encode(fileUploadConfig, forKey: .fileUploadConfig)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(snsTopicArn, forKey: .snsTopicArn)
        
        try container.encode(disablePermissionsChecks, forKey: .disablePermissionsChecks)
        
        try container.encode(imageModerationLabels, forKey: .imageModerationLabels)
        
        try container.encode(organization, forKey: .organization)
        
        try container.encode(sqsKey, forKey: .sqsKey)
        
        try container.encode(suspended, forKey: .suspended)
        
        try container.encode(datadogInfo, forKey: .datadogInfo)
        
        try container.encode(imageModerationEnabled, forKey: .imageModerationEnabled)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(snsKey, forKey: .snsKey)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(agoraOptions, forKey: .agoraOptions)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(asyncUrlEnrichEnabled, forKey: .asyncUrlEnrichEnabled)
        
        try container.encode(disableAuthChecks, forKey: .disableAuthChecks)
        
        try container.encode(multiTenantEnabled, forKey: .multiTenantEnabled)
        
        try container.encode(policies, forKey: .policies)
    }
}
