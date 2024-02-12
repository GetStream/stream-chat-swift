//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct App: Codable, Hashable {
    public var asyncUrlEnrichEnabled: Bool
    public var campaignEnabled: Bool
    public var cdnExpirationSeconds: Int
    public var customActionHandlerUrl: String
    public var disableAuthChecks: Bool
    public var disablePermissionsChecks: Bool
    public var enforceUniqueUsernames: String
    public var imageModerationEnabled: Bool
    public var multiTenantEnabled: Bool
    public var name: String
    public var organization: String
    public var permissionVersion: String
    public var remindersInterval: Int
    public var snsKey: String
    public var snsSecret: String
    public var snsTopicArn: String
    public var sqsKey: String
    public var sqsSecret: String
    public var sqsUrl: String
    public var suspended: Bool
    public var suspendedExplanation: String
    public var videoProvider: String
    public var webhookUrl: String
    public var userSearchDisallowedRoles: [String]
    public var webhookEvents: [String]
    public var callTypes: [String: CallType?]
    public var channelConfigs: [String: ChannelConfig?]
    public var fileUploadConfig: FileUploadConfig
    public var grants: [String: [String]]
    public var imageUploadConfig: FileUploadConfig
    public var policies: [String: [Policy]]
    public var pushNotifications: PushNotificationFields
    public var autoTranslationEnabled: Bool? = nil
    public var beforeMessageSendHookUrl: String? = nil
    public var revokeTokensIssuedBefore: Date? = nil
    public var allowedFlagReasons: [String]? = nil
    public var geofences: [GeofenceResponse?]? = nil
    public var imageModerationLabels: [String]? = nil
    public var agoraOptions: Config? = nil
    public var datadogInfo: DataDogInfo? = nil
    public var hmsOptions: Config? = nil

    public init(asyncUrlEnrichEnabled: Bool, campaignEnabled: Bool, cdnExpirationSeconds: Int, customActionHandlerUrl: String, disableAuthChecks: Bool, disablePermissionsChecks: Bool, enforceUniqueUsernames: String, imageModerationEnabled: Bool, multiTenantEnabled: Bool, name: String, organization: String, permissionVersion: String, remindersInterval: Int, snsKey: String, snsSecret: String, snsTopicArn: String, sqsKey: String, sqsSecret: String, sqsUrl: String, suspended: Bool, suspendedExplanation: String, videoProvider: String, webhookUrl: String, userSearchDisallowedRoles: [String], webhookEvents: [String], callTypes: [String: CallType?], channelConfigs: [String: ChannelConfig?], fileUploadConfig: FileUploadConfig, grants: [String: [String]], imageUploadConfig: FileUploadConfig, policies: [String: [Policy]], pushNotifications: PushNotificationFields, autoTranslationEnabled: Bool? = nil, beforeMessageSendHookUrl: String? = nil, revokeTokensIssuedBefore: Date? = nil, allowedFlagReasons: [String]? = nil, geofences: [GeofenceResponse?]? = nil, imageModerationLabels: [String]? = nil, agoraOptions: Config? = nil, datadogInfo: DataDogInfo? = nil, hmsOptions: Config? = nil) {
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        self.campaignEnabled = campaignEnabled
        self.cdnExpirationSeconds = cdnExpirationSeconds
        self.customActionHandlerUrl = customActionHandlerUrl
        self.disableAuthChecks = disableAuthChecks
        self.disablePermissionsChecks = disablePermissionsChecks
        self.enforceUniqueUsernames = enforceUniqueUsernames
        self.imageModerationEnabled = imageModerationEnabled
        self.multiTenantEnabled = multiTenantEnabled
        self.name = name
        self.organization = organization
        self.permissionVersion = permissionVersion
        self.remindersInterval = remindersInterval
        self.snsKey = snsKey
        self.snsSecret = snsSecret
        self.snsTopicArn = snsTopicArn
        self.sqsKey = sqsKey
        self.sqsSecret = sqsSecret
        self.sqsUrl = sqsUrl
        self.suspended = suspended
        self.suspendedExplanation = suspendedExplanation
        self.videoProvider = videoProvider
        self.webhookUrl = webhookUrl
        self.userSearchDisallowedRoles = userSearchDisallowedRoles
        self.webhookEvents = webhookEvents
        self.callTypes = callTypes
        self.channelConfigs = channelConfigs
        self.fileUploadConfig = fileUploadConfig
        self.grants = grants
        self.imageUploadConfig = imageUploadConfig
        self.policies = policies
        self.pushNotifications = pushNotifications
        self.autoTranslationEnabled = autoTranslationEnabled
        self.beforeMessageSendHookUrl = beforeMessageSendHookUrl
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
        self.allowedFlagReasons = allowedFlagReasons
        self.geofences = geofences
        self.imageModerationLabels = imageModerationLabels
        self.agoraOptions = agoraOptions
        self.datadogInfo = datadogInfo
        self.hmsOptions = hmsOptions
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        case campaignEnabled = "campaign_enabled"
        case cdnExpirationSeconds = "cdn_expiration_seconds"
        case customActionHandlerUrl = "custom_action_handler_url"
        case disableAuthChecks = "disable_auth_checks"
        case disablePermissionsChecks = "disable_permissions_checks"
        case enforceUniqueUsernames = "enforce_unique_usernames"
        case imageModerationEnabled = "image_moderation_enabled"
        case multiTenantEnabled = "multi_tenant_enabled"
        case name
        case organization
        case permissionVersion = "permission_version"
        case remindersInterval = "reminders_interval"
        case snsKey = "sns_key"
        case snsSecret = "sns_secret"
        case snsTopicArn = "sns_topic_arn"
        case sqsKey = "sqs_key"
        case sqsSecret = "sqs_secret"
        case sqsUrl = "sqs_url"
        case suspended
        case suspendedExplanation = "suspended_explanation"
        case videoProvider = "video_provider"
        case webhookUrl = "webhook_url"
        case userSearchDisallowedRoles = "user_search_disallowed_roles"
        case webhookEvents = "webhook_events"
        case callTypes = "call_types"
        case channelConfigs = "channel_configs"
        case fileUploadConfig = "file_upload_config"
        case grants
        case imageUploadConfig = "image_upload_config"
        case policies
        case pushNotifications = "push_notifications"
        case autoTranslationEnabled = "auto_translation_enabled"
        case beforeMessageSendHookUrl = "before_message_send_hook_url"
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
        case allowedFlagReasons = "allowed_flag_reasons"
        case geofences
        case imageModerationLabels = "image_moderation_labels"
        case agoraOptions = "agora_options"
        case datadogInfo = "datadog_info"
        case hmsOptions = "hms_options"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(asyncUrlEnrichEnabled, forKey: .asyncUrlEnrichEnabled)
        try container.encode(campaignEnabled, forKey: .campaignEnabled)
        try container.encode(cdnExpirationSeconds, forKey: .cdnExpirationSeconds)
        try container.encode(customActionHandlerUrl, forKey: .customActionHandlerUrl)
        try container.encode(disableAuthChecks, forKey: .disableAuthChecks)
        try container.encode(disablePermissionsChecks, forKey: .disablePermissionsChecks)
        try container.encode(enforceUniqueUsernames, forKey: .enforceUniqueUsernames)
        try container.encode(imageModerationEnabled, forKey: .imageModerationEnabled)
        try container.encode(multiTenantEnabled, forKey: .multiTenantEnabled)
        try container.encode(name, forKey: .name)
        try container.encode(organization, forKey: .organization)
        try container.encode(permissionVersion, forKey: .permissionVersion)
        try container.encode(remindersInterval, forKey: .remindersInterval)
        try container.encode(snsKey, forKey: .snsKey)
        try container.encode(snsSecret, forKey: .snsSecret)
        try container.encode(snsTopicArn, forKey: .snsTopicArn)
        try container.encode(sqsKey, forKey: .sqsKey)
        try container.encode(sqsSecret, forKey: .sqsSecret)
        try container.encode(sqsUrl, forKey: .sqsUrl)
        try container.encode(suspended, forKey: .suspended)
        try container.encode(suspendedExplanation, forKey: .suspendedExplanation)
        try container.encode(videoProvider, forKey: .videoProvider)
        try container.encode(webhookUrl, forKey: .webhookUrl)
        try container.encode(userSearchDisallowedRoles, forKey: .userSearchDisallowedRoles)
        try container.encode(webhookEvents, forKey: .webhookEvents)
        try container.encode(callTypes, forKey: .callTypes)
        try container.encode(channelConfigs, forKey: .channelConfigs)
        try container.encode(fileUploadConfig, forKey: .fileUploadConfig)
        try container.encode(grants, forKey: .grants)
        try container.encode(imageUploadConfig, forKey: .imageUploadConfig)
        try container.encode(policies, forKey: .policies)
        try container.encode(pushNotifications, forKey: .pushNotifications)
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        try container.encode(beforeMessageSendHookUrl, forKey: .beforeMessageSendHookUrl)
        try container.encode(revokeTokensIssuedBefore, forKey: .revokeTokensIssuedBefore)
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        try container.encode(geofences, forKey: .geofences)
        try container.encode(imageModerationLabels, forKey: .imageModerationLabels)
        try container.encode(agoraOptions, forKey: .agoraOptions)
        try container.encode(datadogInfo, forKey: .datadogInfo)
        try container.encode(hmsOptions, forKey: .hmsOptions)
    }
}
