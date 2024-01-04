//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatApp: Codable, Hashable {
    public var agoraOptions: StreamChatConfig?
    
    public var campaignEnabled: Bool
    
    public var name: String
    
    public var organization: String
    
    public var snsSecret: String
    
    public var multiTenantEnabled: Bool
    
    public var customActionHandlerUrl: String
    
    public var datadogInfo: StreamChatDataDogInfo?
    
    public var disablePermissionsChecks: Bool
    
    public var grants: [String: RawJSON]
    
    public var imageModerationEnabled: Bool
    
    public var imageModerationLabels: [String]?
    
    public var fileUploadConfig: StreamChatFileUploadConfig
    
    public var snsTopicArn: String
    
    public var userSearchDisallowedRoles: [String]
    
    public var asyncUrlEnrichEnabled: Bool
    
    public var policies: [String: RawJSON]
    
    public var searchBackend: String
    
    public var snsKey: String
    
    public var sqsUrl: String
    
    public var suspendedExplanation: String
    
    public var suspended: Bool
    
    public var webhookEvents: [String]
    
    public var allowedFlagReasons: [String]?
    
    public var autoTranslationEnabled: Bool?
    
    public var beforeMessageSendHookUrl: String?
    
    public var disableAuthChecks: Bool
    
    public var permissionVersion: String
    
    public var pushNotifications: StreamChatPushNotificationFields
    
    public var sqsKey: String
    
    public var sqsSecret: String
    
    public var cdnExpirationSeconds: Int
    
    public var enforceUniqueUsernames: String
    
    public var geofences: [StreamChatGeofenceResponse?]?
    
    public var imageUploadConfig: StreamChatFileUploadConfig
    
    public var remindersInterval: Int
    
    public var revokeTokensIssuedBefore: String?
    
    public var callTypes: [String: RawJSON]
    
    public var channelConfigs: [String: RawJSON]
    
    public var hmsOptions: StreamChatConfig?
    
    public var videoProvider: String
    
    public var webhookUrl: String
    
    public init(agoraOptions: StreamChatConfig?, campaignEnabled: Bool, name: String, organization: String, snsSecret: String, multiTenantEnabled: Bool, customActionHandlerUrl: String, datadogInfo: StreamChatDataDogInfo?, disablePermissionsChecks: Bool, grants: [String: RawJSON], imageModerationEnabled: Bool, imageModerationLabels: [String]?, fileUploadConfig: StreamChatFileUploadConfig, snsTopicArn: String, userSearchDisallowedRoles: [String], asyncUrlEnrichEnabled: Bool, policies: [String: RawJSON], searchBackend: String, snsKey: String, sqsUrl: String, suspendedExplanation: String, suspended: Bool, webhookEvents: [String], allowedFlagReasons: [String]?, autoTranslationEnabled: Bool?, beforeMessageSendHookUrl: String?, disableAuthChecks: Bool, permissionVersion: String, pushNotifications: StreamChatPushNotificationFields, sqsKey: String, sqsSecret: String, cdnExpirationSeconds: Int, enforceUniqueUsernames: String, geofences: [StreamChatGeofenceResponse?]?, imageUploadConfig: StreamChatFileUploadConfig, remindersInterval: Int, revokeTokensIssuedBefore: String?, callTypes: [String: RawJSON], channelConfigs: [String: RawJSON], hmsOptions: StreamChatConfig?, videoProvider: String, webhookUrl: String) {
        self.agoraOptions = agoraOptions
        
        self.campaignEnabled = campaignEnabled
        
        self.name = name
        
        self.organization = organization
        
        self.snsSecret = snsSecret
        
        self.multiTenantEnabled = multiTenantEnabled
        
        self.customActionHandlerUrl = customActionHandlerUrl
        
        self.datadogInfo = datadogInfo
        
        self.disablePermissionsChecks = disablePermissionsChecks
        
        self.grants = grants
        
        self.imageModerationEnabled = imageModerationEnabled
        
        self.imageModerationLabels = imageModerationLabels
        
        self.fileUploadConfig = fileUploadConfig
        
        self.snsTopicArn = snsTopicArn
        
        self.userSearchDisallowedRoles = userSearchDisallowedRoles
        
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        
        self.policies = policies
        
        self.searchBackend = searchBackend
        
        self.snsKey = snsKey
        
        self.sqsUrl = sqsUrl
        
        self.suspendedExplanation = suspendedExplanation
        
        self.suspended = suspended
        
        self.webhookEvents = webhookEvents
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.beforeMessageSendHookUrl = beforeMessageSendHookUrl
        
        self.disableAuthChecks = disableAuthChecks
        
        self.permissionVersion = permissionVersion
        
        self.pushNotifications = pushNotifications
        
        self.sqsKey = sqsKey
        
        self.sqsSecret = sqsSecret
        
        self.cdnExpirationSeconds = cdnExpirationSeconds
        
        self.enforceUniqueUsernames = enforceUniqueUsernames
        
        self.geofences = geofences
        
        self.imageUploadConfig = imageUploadConfig
        
        self.remindersInterval = remindersInterval
        
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        
        self.callTypes = callTypes
        
        self.channelConfigs = channelConfigs
        
        self.hmsOptions = hmsOptions
        
        self.videoProvider = videoProvider
        
        self.webhookUrl = webhookUrl
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case agoraOptions = "agora_options"
        
        case campaignEnabled = "campaign_enabled"
        
        case name
        
        case organization
        
        case snsSecret = "sns_secret"
        
        case multiTenantEnabled = "multi_tenant_enabled"
        
        case customActionHandlerUrl = "custom_action_handler_url"
        
        case datadogInfo = "datadog_info"
        
        case disablePermissionsChecks = "disable_permissions_checks"
        
        case grants
        
        case imageModerationEnabled = "image_moderation_enabled"
        
        case imageModerationLabels = "image_moderation_labels"
        
        case fileUploadConfig = "file_upload_config"
        
        case snsTopicArn = "sns_topic_arn"
        
        case userSearchDisallowedRoles = "user_search_disallowed_roles"
        
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        
        case policies
        
        case searchBackend = "search_backend"
        
        case snsKey = "sns_key"
        
        case sqsUrl = "sqs_url"
        
        case suspendedExplanation = "suspended_explanation"
        
        case suspended
        
        case webhookEvents = "webhook_events"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case beforeMessageSendHookUrl = "before_message_send_hook_url"
        
        case disableAuthChecks = "disable_auth_checks"
        
        case permissionVersion = "permission_version"
        
        case pushNotifications = "push_notifications"
        
        case sqsKey = "sqs_key"
        
        case sqsSecret = "sqs_secret"
        
        case cdnExpirationSeconds = "cdn_expiration_seconds"
        
        case enforceUniqueUsernames = "enforce_unique_usernames"
        
        case geofences
        
        case imageUploadConfig = "image_upload_config"
        
        case remindersInterval = "reminders_interval"
        
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        
        case callTypes = "call_types"
        
        case channelConfigs = "channel_configs"
        
        case hmsOptions = "hms_options"
        
        case videoProvider = "video_provider"
        
        case webhookUrl = "webhook_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(agoraOptions, forKey: .agoraOptions)
        
        try container.encode(campaignEnabled, forKey: .campaignEnabled)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(organization, forKey: .organization)
        
        try container.encode(snsSecret, forKey: .snsSecret)
        
        try container.encode(multiTenantEnabled, forKey: .multiTenantEnabled)
        
        try container.encode(customActionHandlerUrl, forKey: .customActionHandlerUrl)
        
        try container.encode(datadogInfo, forKey: .datadogInfo)
        
        try container.encode(disablePermissionsChecks, forKey: .disablePermissionsChecks)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(imageModerationEnabled, forKey: .imageModerationEnabled)
        
        try container.encode(imageModerationLabels, forKey: .imageModerationLabels)
        
        try container.encode(fileUploadConfig, forKey: .fileUploadConfig)
        
        try container.encode(snsTopicArn, forKey: .snsTopicArn)
        
        try container.encode(userSearchDisallowedRoles, forKey: .userSearchDisallowedRoles)
        
        try container.encode(asyncUrlEnrichEnabled, forKey: .asyncUrlEnrichEnabled)
        
        try container.encode(policies, forKey: .policies)
        
        try container.encode(searchBackend, forKey: .searchBackend)
        
        try container.encode(snsKey, forKey: .snsKey)
        
        try container.encode(sqsUrl, forKey: .sqsUrl)
        
        try container.encode(suspendedExplanation, forKey: .suspendedExplanation)
        
        try container.encode(suspended, forKey: .suspended)
        
        try container.encode(webhookEvents, forKey: .webhookEvents)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(beforeMessageSendHookUrl, forKey: .beforeMessageSendHookUrl)
        
        try container.encode(disableAuthChecks, forKey: .disableAuthChecks)
        
        try container.encode(permissionVersion, forKey: .permissionVersion)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(sqsKey, forKey: .sqsKey)
        
        try container.encode(sqsSecret, forKey: .sqsSecret)
        
        try container.encode(cdnExpirationSeconds, forKey: .cdnExpirationSeconds)
        
        try container.encode(enforceUniqueUsernames, forKey: .enforceUniqueUsernames)
        
        try container.encode(geofences, forKey: .geofences)
        
        try container.encode(imageUploadConfig, forKey: .imageUploadConfig)
        
        try container.encode(remindersInterval, forKey: .remindersInterval)
        
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        
        try container.encode(callTypes, forKey: .callTypes)
        
        try container.encode(channelConfigs, forKey: .channelConfigs)
        
        try container.encode(hmsOptions, forKey: .hmsOptions)
        
        try container.encode(videoProvider, forKey: .videoProvider)
        
        try container.encode(webhookUrl, forKey: .webhookUrl)
    }
}
