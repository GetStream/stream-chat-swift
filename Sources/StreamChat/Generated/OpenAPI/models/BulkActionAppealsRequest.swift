//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BulkActionAppealsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum BulkActionAppealsRequestActionType: String, Sendable, Codable, CaseIterable {
        case markReviewed = "mark_reviewed"
        case rejectAppeal = "reject_appeal"
        case restore
        case unban
        case unblock
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

    /// Action to apply: unban, restore, unblock, mark_reviewed, or reject_appeal
    var actionType: BulkActionAppealsRequestActionType
    /// List of appeal UUIDs to process
    var appealIds: [String]
    var markReviewed: MarkReviewedRequestPayload?
    var rejectAppeal: RejectAppealRequestPayload?
    var restore: RestoreActionRequestPayload?
    var unban: UnbanActionRequestPayload?
    var unblock: UnblockActionRequestPayload?

    init(actionType: BulkActionAppealsRequestActionType, appealIds: [String], markReviewed: MarkReviewedRequestPayload? = nil, rejectAppeal: RejectAppealRequestPayload? = nil, restore: RestoreActionRequestPayload? = nil, unban: UnbanActionRequestPayload? = nil, unblock: UnblockActionRequestPayload? = nil) {
        self.actionType = actionType
        self.appealIds = appealIds
        self.markReviewed = markReviewed
        self.rejectAppeal = rejectAppeal
        self.restore = restore
        self.unban = unban
        self.unblock = unblock
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionType = "action_type"
        case appealIds = "appeal_ids"
        case markReviewed = "mark_reviewed"
        case rejectAppeal = "reject_appeal"
        case restore
        case unban
        case unblock
    }

    static func == (lhs: BulkActionAppealsRequest, rhs: BulkActionAppealsRequest) -> Bool {
        lhs.actionType == rhs.actionType &&
            lhs.appealIds == rhs.appealIds &&
            lhs.markReviewed == rhs.markReviewed &&
            lhs.rejectAppeal == rhs.rejectAppeal &&
            lhs.restore == rhs.restore &&
            lhs.unban == rhs.unban &&
            lhs.unblock == rhs.unblock
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionType)
        hasher.combine(appealIds)
        hasher.combine(markReviewed)
        hasher.combine(rejectAppeal)
        hasher.combine(restore)
        hasher.combine(unban)
        hasher.combine(unblock)
    }
}
