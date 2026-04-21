//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var aiImageConfig: AIImageConfig?
    /// Configurable image moderation label definitions for dashboard rendering
    var aiImageLabelDefinitions: [AIImageLabelDefinition]?
    /// Available L2 subclassifications per L1 image moderation label, based on the active provider
    var aiImageSubclassifications: [String: [String]]?
    var aiTextConfig: AITextConfig?
    var aiVideoConfig: AIVideoConfig?
    /// Whether moderation should be performed asynchronously
    var async: Bool
    var automodPlatformCircumventionConfig: AutomodPlatformCircumventionConfig?
    var automodSemanticFiltersConfig: AutomodSemanticFiltersConfig?
    var automodToxicityConfig: AutomodToxicityConfig?
    var blockListConfig: BlockListConfig?
    /// When the configuration was created
    var createdAt: Date
    /// Unique identifier for the moderation configuration
    var key: String
    var llmConfig: LLMConfig?
    var supportedVideoCallHarmTypes: [String]
    /// Team associated with the configuration
    var team: String
    /// When the configuration was last updated
    var updatedAt: Date
    var velocityFilterConfig: VelocityFilterConfig?
    var videoCallRuleConfig: VideoCallRuleConfig?

    init(aiImageConfig: AIImageConfig? = nil, aiImageLabelDefinitions: [AIImageLabelDefinition]? = nil, aiImageSubclassifications: [String: [String]]? = nil, aiTextConfig: AITextConfig? = nil, aiVideoConfig: AIVideoConfig? = nil, async: Bool, automodPlatformCircumventionConfig: AutomodPlatformCircumventionConfig? = nil, automodSemanticFiltersConfig: AutomodSemanticFiltersConfig? = nil, automodToxicityConfig: AutomodToxicityConfig? = nil, blockListConfig: BlockListConfig? = nil, createdAt: Date, key: String, llmConfig: LLMConfig? = nil, supportedVideoCallHarmTypes: [String], team: String, updatedAt: Date, velocityFilterConfig: VelocityFilterConfig? = nil, videoCallRuleConfig: VideoCallRuleConfig? = nil) {
        self.aiImageConfig = aiImageConfig
        self.aiImageLabelDefinitions = aiImageLabelDefinitions
        self.aiImageSubclassifications = aiImageSubclassifications
        self.aiTextConfig = aiTextConfig
        self.aiVideoConfig = aiVideoConfig
        self.async = async
        self.automodPlatformCircumventionConfig = automodPlatformCircumventionConfig
        self.automodSemanticFiltersConfig = automodSemanticFiltersConfig
        self.automodToxicityConfig = automodToxicityConfig
        self.blockListConfig = blockListConfig
        self.createdAt = createdAt
        self.key = key
        self.llmConfig = llmConfig
        self.supportedVideoCallHarmTypes = supportedVideoCallHarmTypes
        self.team = team
        self.updatedAt = updatedAt
        self.velocityFilterConfig = velocityFilterConfig
        self.videoCallRuleConfig = videoCallRuleConfig
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case aiImageConfig = "ai_image_config"
        case aiImageLabelDefinitions = "ai_image_label_definitions"
        case aiImageSubclassifications = "ai_image_subclassifications"
        case aiTextConfig = "ai_text_config"
        case aiVideoConfig = "ai_video_config"
        case async
        case automodPlatformCircumventionConfig = "automod_platform_circumvention_config"
        case automodSemanticFiltersConfig = "automod_semantic_filters_config"
        case automodToxicityConfig = "automod_toxicity_config"
        case blockListConfig = "block_list_config"
        case createdAt = "created_at"
        case key
        case llmConfig = "llm_config"
        case supportedVideoCallHarmTypes = "supported_video_call_harm_types"
        case team
        case updatedAt = "updated_at"
        case velocityFilterConfig = "velocity_filter_config"
        case videoCallRuleConfig = "video_call_rule_config"
    }

    static func == (lhs: ConfigResponse, rhs: ConfigResponse) -> Bool {
        lhs.aiImageConfig == rhs.aiImageConfig &&
            lhs.aiImageLabelDefinitions == rhs.aiImageLabelDefinitions &&
            lhs.aiImageSubclassifications == rhs.aiImageSubclassifications &&
            lhs.aiTextConfig == rhs.aiTextConfig &&
            lhs.aiVideoConfig == rhs.aiVideoConfig &&
            lhs.async == rhs.async &&
            lhs.automodPlatformCircumventionConfig == rhs.automodPlatformCircumventionConfig &&
            lhs.automodSemanticFiltersConfig == rhs.automodSemanticFiltersConfig &&
            lhs.automodToxicityConfig == rhs.automodToxicityConfig &&
            lhs.blockListConfig == rhs.blockListConfig &&
            lhs.createdAt == rhs.createdAt &&
            lhs.key == rhs.key &&
            lhs.llmConfig == rhs.llmConfig &&
            lhs.supportedVideoCallHarmTypes == rhs.supportedVideoCallHarmTypes &&
            lhs.team == rhs.team &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.velocityFilterConfig == rhs.velocityFilterConfig &&
            lhs.videoCallRuleConfig == rhs.videoCallRuleConfig
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(aiImageConfig)
        hasher.combine(aiImageLabelDefinitions)
        hasher.combine(aiImageSubclassifications)
        hasher.combine(aiTextConfig)
        hasher.combine(aiVideoConfig)
        hasher.combine(async)
        hasher.combine(automodPlatformCircumventionConfig)
        hasher.combine(automodSemanticFiltersConfig)
        hasher.combine(automodToxicityConfig)
        hasher.combine(blockListConfig)
        hasher.combine(createdAt)
        hasher.combine(key)
        hasher.combine(llmConfig)
        hasher.combine(supportedVideoCallHarmTypes)
        hasher.combine(team)
        hasher.combine(updatedAt)
        hasher.combine(velocityFilterConfig)
        hasher.combine(videoCallRuleConfig)
    }
}
