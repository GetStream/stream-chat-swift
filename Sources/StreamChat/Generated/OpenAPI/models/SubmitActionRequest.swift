//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SubmitActionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum SubmitActionRequestActionType: String, Sendable, Codable, CaseIterable {
        case ban
        case block
        case bypass
        case custom
        case deEscalate = "de_escalate"
        case deleteActivity = "delete_activity"
        case deleteComment = "delete_comment"
        case deleteMessage = "delete_message"
        case deleteReaction = "delete_reaction"
        case deleteUser = "delete_user"
        case endCall = "end_call"
        case escalate
        case flag
        case kickUser = "kick_user"
        case markReviewed = "mark_reviewed"
        case rejectAppeal = "reject_appeal"
        case restore
        case shadowBlock = "shadow_block"
        case unban
        case unblock
        case unmask
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

    /// Type of moderation action to perform. One of: mark_reviewed, delete_message, delete_activity, delete_comment, delete_reaction, ban, custom, unban, restore, delete_user, unblock, block, shadow_block, unmask, kick_user, end_call, escalate, de_escalate
    var actionType: SubmitActionRequestActionType
    /// UUID of the appeal to act on (required for reject_appeal, optional for other actions)
    var appealId: String?
    var ban: BanActionRequestPayload?
    var block: BlockActionRequestPayload?
    var bypass: BypassActionRequest?
    var custom: CustomActionRequestPayload?
    var deleteActivity: DeleteActivityRequestPayload?
    var deleteComment: DeleteCommentRequestPayload?
    var deleteMessage: DeleteMessageRequestPayload?
    var deleteReaction: DeleteReactionRequestPayload?
    var deleteUser: DeleteUserRequestPayload?
    var escalate: EscalatePayload?
    var flag: FlagRequest?
    /// UUID of the review queue item to act on
    var itemId: String?
    var markReviewed: MarkReviewedRequestPayload?
    var rejectAppeal: RejectAppealRequestPayload?
    var restore: RestoreActionRequestPayload?
    var shadowBlock: ShadowBlockActionRequestPayload?
    var unban: UnbanActionRequestPayload?
    var unblock: UnblockActionRequestPayload?

    init(actionType: SubmitActionRequestActionType, appealId: String? = nil, ban: BanActionRequestPayload? = nil, block: BlockActionRequestPayload? = nil, bypass: BypassActionRequest? = nil, custom: CustomActionRequestPayload? = nil, deleteActivity: DeleteActivityRequestPayload? = nil, deleteComment: DeleteCommentRequestPayload? = nil, deleteMessage: DeleteMessageRequestPayload? = nil, deleteReaction: DeleteReactionRequestPayload? = nil, deleteUser: DeleteUserRequestPayload? = nil, escalate: EscalatePayload? = nil, flag: FlagRequest? = nil, itemId: String? = nil, markReviewed: MarkReviewedRequestPayload? = nil, rejectAppeal: RejectAppealRequestPayload? = nil, restore: RestoreActionRequestPayload? = nil, shadowBlock: ShadowBlockActionRequestPayload? = nil, unban: UnbanActionRequestPayload? = nil, unblock: UnblockActionRequestPayload? = nil) {
        self.actionType = actionType
        self.appealId = appealId
        self.ban = ban
        self.block = block
        self.bypass = bypass
        self.custom = custom
        self.deleteActivity = deleteActivity
        self.deleteComment = deleteComment
        self.deleteMessage = deleteMessage
        self.deleteReaction = deleteReaction
        self.deleteUser = deleteUser
        self.escalate = escalate
        self.flag = flag
        self.itemId = itemId
        self.markReviewed = markReviewed
        self.rejectAppeal = rejectAppeal
        self.restore = restore
        self.shadowBlock = shadowBlock
        self.unban = unban
        self.unblock = unblock
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionType = "action_type"
        case appealId = "appeal_id"
        case ban
        case block
        case bypass
        case custom
        case deleteActivity = "delete_activity"
        case deleteComment = "delete_comment"
        case deleteMessage = "delete_message"
        case deleteReaction = "delete_reaction"
        case deleteUser = "delete_user"
        case escalate
        case flag
        case itemId = "item_id"
        case markReviewed = "mark_reviewed"
        case rejectAppeal = "reject_appeal"
        case restore
        case shadowBlock = "shadow_block"
        case unban
        case unblock
    }

    static func == (lhs: SubmitActionRequest, rhs: SubmitActionRequest) -> Bool {
        lhs.actionType == rhs.actionType &&
            lhs.appealId == rhs.appealId &&
            lhs.ban == rhs.ban &&
            lhs.block == rhs.block &&
            lhs.bypass == rhs.bypass &&
            lhs.custom == rhs.custom &&
            lhs.deleteActivity == rhs.deleteActivity &&
            lhs.deleteComment == rhs.deleteComment &&
            lhs.deleteMessage == rhs.deleteMessage &&
            lhs.deleteReaction == rhs.deleteReaction &&
            lhs.deleteUser == rhs.deleteUser &&
            lhs.escalate == rhs.escalate &&
            lhs.flag == rhs.flag &&
            lhs.itemId == rhs.itemId &&
            lhs.markReviewed == rhs.markReviewed &&
            lhs.rejectAppeal == rhs.rejectAppeal &&
            lhs.restore == rhs.restore &&
            lhs.shadowBlock == rhs.shadowBlock &&
            lhs.unban == rhs.unban &&
            lhs.unblock == rhs.unblock
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionType)
        hasher.combine(appealId)
        hasher.combine(ban)
        hasher.combine(block)
        hasher.combine(bypass)
        hasher.combine(custom)
        hasher.combine(deleteActivity)
        hasher.combine(deleteComment)
        hasher.combine(deleteMessage)
        hasher.combine(deleteReaction)
        hasher.combine(deleteUser)
        hasher.combine(escalate)
        hasher.combine(flag)
        hasher.combine(itemId)
        hasher.combine(markReviewed)
        hasher.combine(rejectAppeal)
        hasher.combine(restore)
        hasher.combine(shadowBlock)
        hasher.combine(unban)
        hasher.combine(unblock)
    }
}
