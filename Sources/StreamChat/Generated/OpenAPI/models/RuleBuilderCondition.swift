//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RuleBuilderCondition: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var callCustomPropertyParams: CallCustomPropertyParameters?
    var callTypeRuleParams: CallTypeRuleParameters?
    var callViolationCountParams: CallViolationCountParameters?
    var closedCaptionRuleParams: ClosedCaptionRuleParameters?
    var confidence: Float?
    var contentCountRuleParams: ContentCountRuleParameters?
    var contentFlagCountRuleParams: FlagCountRuleParameters?
    var imageContentParams: ImageContentParameters?
    var imageRuleParams: ImageRuleParameters?
    var keyframeRuleParams: KeyframeRuleParameters?
    var textContentParams: TextContentParameters?
    var textRuleParams: TextRuleParameters?
    var type: String?
    var userCreatedWithinParams: UserCreatedWithinParameters?
    var userCustomPropertyParams: UserCustomPropertyParameters?
    var userFlagCountRuleParams: FlagCountRuleParameters?
    var userIdenticalContentCountParams: UserIdenticalContentCountParameters?
    var userRoleParams: UserRoleParameters?
    var userRuleParams: UserRuleParameters?
    var videoContentParams: VideoContentParameters?
    var videoRuleParams: VideoRuleParameters?

    init(callCustomPropertyParams: CallCustomPropertyParameters? = nil, callTypeRuleParams: CallTypeRuleParameters? = nil, callViolationCountParams: CallViolationCountParameters? = nil, closedCaptionRuleParams: ClosedCaptionRuleParameters? = nil, confidence: Float? = nil, contentCountRuleParams: ContentCountRuleParameters? = nil, contentFlagCountRuleParams: FlagCountRuleParameters? = nil, imageContentParams: ImageContentParameters? = nil, imageRuleParams: ImageRuleParameters? = nil, keyframeRuleParams: KeyframeRuleParameters? = nil, textContentParams: TextContentParameters? = nil, textRuleParams: TextRuleParameters? = nil, userCreatedWithinParams: UserCreatedWithinParameters? = nil, userCustomPropertyParams: UserCustomPropertyParameters? = nil, userFlagCountRuleParams: FlagCountRuleParameters? = nil, userIdenticalContentCountParams: UserIdenticalContentCountParameters? = nil, userRoleParams: UserRoleParameters? = nil, userRuleParams: UserRuleParameters? = nil, videoContentParams: VideoContentParameters? = nil, videoRuleParams: VideoRuleParameters? = nil) {
        self.callCustomPropertyParams = callCustomPropertyParams
        self.callTypeRuleParams = callTypeRuleParams
        self.callViolationCountParams = callViolationCountParams
        self.closedCaptionRuleParams = closedCaptionRuleParams
        self.confidence = confidence
        self.contentCountRuleParams = contentCountRuleParams
        self.contentFlagCountRuleParams = contentFlagCountRuleParams
        self.imageContentParams = imageContentParams
        self.imageRuleParams = imageRuleParams
        self.keyframeRuleParams = keyframeRuleParams
        self.textContentParams = textContentParams
        self.textRuleParams = textRuleParams
        self.userCreatedWithinParams = userCreatedWithinParams
        self.userCustomPropertyParams = userCustomPropertyParams
        self.userFlagCountRuleParams = userFlagCountRuleParams
        self.userIdenticalContentCountParams = userIdenticalContentCountParams
        self.userRoleParams = userRoleParams
        self.userRuleParams = userRuleParams
        self.videoContentParams = videoContentParams
        self.videoRuleParams = videoRuleParams
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case callCustomPropertyParams = "call_custom_property_params"
        case callTypeRuleParams = "call_type_rule_params"
        case callViolationCountParams = "call_violation_count_params"
        case closedCaptionRuleParams = "closed_caption_rule_params"
        case confidence
        case contentCountRuleParams = "content_count_rule_params"
        case contentFlagCountRuleParams = "content_flag_count_rule_params"
        case imageContentParams = "image_content_params"
        case imageRuleParams = "image_rule_params"
        case keyframeRuleParams = "keyframe_rule_params"
        case textContentParams = "text_content_params"
        case textRuleParams = "text_rule_params"
        case type
        case userCreatedWithinParams = "user_created_within_params"
        case userCustomPropertyParams = "user_custom_property_params"
        case userFlagCountRuleParams = "user_flag_count_rule_params"
        case userIdenticalContentCountParams = "user_identical_content_count_params"
        case userRoleParams = "user_role_params"
        case userRuleParams = "user_rule_params"
        case videoContentParams = "video_content_params"
        case videoRuleParams = "video_rule_params"
    }

    static func == (lhs: RuleBuilderCondition, rhs: RuleBuilderCondition) -> Bool {
        lhs.callCustomPropertyParams == rhs.callCustomPropertyParams &&
            lhs.callTypeRuleParams == rhs.callTypeRuleParams &&
            lhs.callViolationCountParams == rhs.callViolationCountParams &&
            lhs.closedCaptionRuleParams == rhs.closedCaptionRuleParams &&
            lhs.confidence == rhs.confidence &&
            lhs.contentCountRuleParams == rhs.contentCountRuleParams &&
            lhs.contentFlagCountRuleParams == rhs.contentFlagCountRuleParams &&
            lhs.imageContentParams == rhs.imageContentParams &&
            lhs.imageRuleParams == rhs.imageRuleParams &&
            lhs.keyframeRuleParams == rhs.keyframeRuleParams &&
            lhs.textContentParams == rhs.textContentParams &&
            lhs.textRuleParams == rhs.textRuleParams &&
            lhs.type == rhs.type &&
            lhs.userCreatedWithinParams == rhs.userCreatedWithinParams &&
            lhs.userCustomPropertyParams == rhs.userCustomPropertyParams &&
            lhs.userFlagCountRuleParams == rhs.userFlagCountRuleParams &&
            lhs.userIdenticalContentCountParams == rhs.userIdenticalContentCountParams &&
            lhs.userRoleParams == rhs.userRoleParams &&
            lhs.userRuleParams == rhs.userRuleParams &&
            lhs.videoContentParams == rhs.videoContentParams &&
            lhs.videoRuleParams == rhs.videoRuleParams
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(callCustomPropertyParams)
        hasher.combine(callTypeRuleParams)
        hasher.combine(callViolationCountParams)
        hasher.combine(closedCaptionRuleParams)
        hasher.combine(confidence)
        hasher.combine(contentCountRuleParams)
        hasher.combine(contentFlagCountRuleParams)
        hasher.combine(imageContentParams)
        hasher.combine(imageRuleParams)
        hasher.combine(keyframeRuleParams)
        hasher.combine(textContentParams)
        hasher.combine(textRuleParams)
        hasher.combine(type)
        hasher.combine(userCreatedWithinParams)
        hasher.combine(userCustomPropertyParams)
        hasher.combine(userFlagCountRuleParams)
        hasher.combine(userIdenticalContentCountParams)
        hasher.combine(userRoleParams)
        hasher.combine(userRuleParams)
        hasher.combine(videoContentParams)
        hasher.combine(videoRuleParams)
    }
}
