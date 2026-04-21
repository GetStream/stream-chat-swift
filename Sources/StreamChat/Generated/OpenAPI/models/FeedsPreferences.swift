//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsPreferences: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum FeedsPreferencesComment: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum FeedsPreferencesCommentMention: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum FeedsPreferencesCommentReaction: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum FeedsPreferencesCommentReply: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum FeedsPreferencesFollow: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum FeedsPreferencesMention: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum FeedsPreferencesReaction: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    /// Push notification preference for comments on user's activities. One of: all, none
    var comment: FeedsPreferencesComment?
    /// Push notification preference for mentions in comments. One of: all, none
    var commentMention: FeedsPreferencesCommentMention?
    /// Push notification preference for reactions on comments. One of: all, none
    var commentReaction: FeedsPreferencesCommentReaction?
    /// Push notification preference for replies to comments. One of: all, none
    var commentReply: FeedsPreferencesCommentReply?
    /// Push notification preferences for custom activity types. Map of activity type to preference (all or none)
    var customActivityTypes: [String: String]?
    /// Push notification preference for new followers. One of: all, none
    var follow: FeedsPreferencesFollow?
    /// Push notification preference for mentions in activities. One of: all, none
    var mention: FeedsPreferencesMention?
    /// Push notification preference for reactions on user's activities or comments. One of: all, none
    var reaction: FeedsPreferencesReaction?

    init(comment: FeedsPreferencesComment? = nil, commentMention: FeedsPreferencesCommentMention? = nil, commentReaction: FeedsPreferencesCommentReaction? = nil, commentReply: FeedsPreferencesCommentReply? = nil, customActivityTypes: [String: String]? = nil, follow: FeedsPreferencesFollow? = nil, mention: FeedsPreferencesMention? = nil, reaction: FeedsPreferencesReaction? = nil) {
        self.comment = comment
        self.commentMention = commentMention
        self.commentReaction = commentReaction
        self.commentReply = commentReply
        self.customActivityTypes = customActivityTypes
        self.follow = follow
        self.mention = mention
        self.reaction = reaction
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case comment
        case commentMention = "comment_mention"
        case commentReaction = "comment_reaction"
        case commentReply = "comment_reply"
        case customActivityTypes = "custom_activity_types"
        case follow
        case mention
        case reaction
    }

    static func == (lhs: FeedsPreferences, rhs: FeedsPreferences) -> Bool {
        lhs.comment == rhs.comment &&
            lhs.commentMention == rhs.commentMention &&
            lhs.commentReaction == rhs.commentReaction &&
            lhs.commentReply == rhs.commentReply &&
            lhs.customActivityTypes == rhs.customActivityTypes &&
            lhs.follow == rhs.follow &&
            lhs.mention == rhs.mention &&
            lhs.reaction == rhs.reaction
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(comment)
        hasher.combine(commentMention)
        hasher.combine(commentReaction)
        hasher.combine(commentReply)
        hasher.combine(customActivityTypes)
        hasher.combine(follow)
        hasher.combine(mention)
        hasher.combine(reaction)
    }
}
