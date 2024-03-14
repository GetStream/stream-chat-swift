//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Flag: Codable, Hashable {
    public var createdAt: Date
    public var createdByAutomod: Bool
    public var updatedAt: Date
    public var approvedAt: Date? = nil
    public var reason: String? = nil
    public var rejectedAt: Date? = nil
    public var reviewedAt: Date? = nil
    public var reviewedBy: String? = nil
    public var targetMessageId: String? = nil
    public var custom: [String: RawJSON]? = nil
    public var details: FlagDetails? = nil
    public var targetMessage: Message? = nil
    public var targetUser: UserObject? = nil
    public var user: UserObject? = nil

    public init(createdAt: Date, createdByAutomod: Bool, updatedAt: Date, approvedAt: Date? = nil, reason: String? = nil, rejectedAt: Date? = nil, reviewedAt: Date? = nil, reviewedBy: String? = nil, targetMessageId: String? = nil, custom: [String: RawJSON]? = nil, details: FlagDetails? = nil, targetMessage: Message? = nil, targetUser: UserObject? = nil, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.createdByAutomod = createdByAutomod
        self.updatedAt = updatedAt
        self.approvedAt = approvedAt
        self.reason = reason
        self.rejectedAt = rejectedAt
        self.reviewedAt = reviewedAt
        self.reviewedBy = reviewedBy
        self.targetMessageId = targetMessageId
        self.custom = custom
        self.details = details
        self.targetMessage = targetMessage
        self.targetUser = targetUser
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case createdByAutomod = "created_by_automod"
        case updatedAt = "updated_at"
        case approvedAt = "approved_at"
        case reason
        case rejectedAt = "rejected_at"
        case reviewedAt = "reviewed_at"
        case reviewedBy = "reviewed_by"
        case targetMessageId = "target_message_id"
        case custom
        case details
        case targetMessage = "target_message"
        case targetUser = "target_user"
        case user
    }
}
