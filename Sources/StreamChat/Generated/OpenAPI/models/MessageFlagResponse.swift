//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageFlagResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var approvedAt: Date?
    var createdAt: Date
    var createdByAutomod: Bool
    var custom: [String: RawJSON]?
    var details: FlagDetailsResponse?
    var message: MessageResponse?
    var moderationFeedback: FlagFeedbackResponse?
    var moderationResult: MessageModerationResult?
    var reason: String?
    var rejectedAt: Date?
    var reviewedAt: Date?
    var reviewedBy: UserResponse?
    var updatedAt: Date
    var user: UserResponse?

    init(approvedAt: Date? = nil, createdAt: Date, createdByAutomod: Bool, custom: [String: RawJSON]? = nil, details: FlagDetailsResponse? = nil, message: MessageResponse? = nil, moderationFeedback: FlagFeedbackResponse? = nil, moderationResult: MessageModerationResult? = nil, reason: String? = nil, rejectedAt: Date? = nil, reviewedAt: Date? = nil, reviewedBy: UserResponse? = nil, updatedAt: Date, user: UserResponse? = nil) {
        self.approvedAt = approvedAt
        self.createdAt = createdAt
        self.createdByAutomod = createdByAutomod
        self.custom = custom
        self.details = details
        self.message = message
        self.moderationFeedback = moderationFeedback
        self.moderationResult = moderationResult
        self.reason = reason
        self.rejectedAt = rejectedAt
        self.reviewedAt = reviewedAt
        self.reviewedBy = reviewedBy
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case approvedAt = "approved_at"
        case createdAt = "created_at"
        case createdByAutomod = "created_by_automod"
        case custom
        case details
        case message
        case moderationFeedback = "moderation_feedback"
        case moderationResult = "moderation_result"
        case reason
        case rejectedAt = "rejected_at"
        case reviewedAt = "reviewed_at"
        case reviewedBy = "reviewed_by"
        case updatedAt = "updated_at"
        case user
    }

    static func == (lhs: MessageFlagResponse, rhs: MessageFlagResponse) -> Bool {
        lhs.approvedAt == rhs.approvedAt &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdByAutomod == rhs.createdByAutomod &&
            lhs.custom == rhs.custom &&
            lhs.details == rhs.details &&
            lhs.message == rhs.message &&
            lhs.moderationFeedback == rhs.moderationFeedback &&
            lhs.moderationResult == rhs.moderationResult &&
            lhs.reason == rhs.reason &&
            lhs.rejectedAt == rhs.rejectedAt &&
            lhs.reviewedAt == rhs.reviewedAt &&
            lhs.reviewedBy == rhs.reviewedBy &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(approvedAt)
        hasher.combine(createdAt)
        hasher.combine(createdByAutomod)
        hasher.combine(custom)
        hasher.combine(details)
        hasher.combine(message)
        hasher.combine(moderationFeedback)
        hasher.combine(moderationResult)
        hasher.combine(reason)
        hasher.combine(rejectedAt)
        hasher.combine(reviewedAt)
        hasher.combine(reviewedBy)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
