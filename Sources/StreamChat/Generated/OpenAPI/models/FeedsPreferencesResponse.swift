//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsPreferencesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var comment: String?
    var commentMention: String?
    var commentReaction: String?
    var commentReply: String?
    var customActivityTypes: [String: String]?
    var follow: String?
    var mention: String?
    var reaction: String?

    init(comment: String? = nil, commentMention: String? = nil, commentReaction: String? = nil, commentReply: String? = nil, customActivityTypes: [String: String]? = nil, follow: String? = nil, mention: String? = nil, reaction: String? = nil) {
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

    static func == (lhs: FeedsPreferencesResponse, rhs: FeedsPreferencesResponse) -> Bool {
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
