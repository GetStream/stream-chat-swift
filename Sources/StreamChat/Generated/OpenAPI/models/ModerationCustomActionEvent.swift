//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationCustomActionEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// The ID of the custom action that was executed
    var actionId: String
    /// Additional options passed to the custom action
    var actionOptions: [String: RawJSON]?
    var createdAt: Date
    var custom: [String: RawJSON]
    var message: MessageResponse?
    var receivedAt: Date?
    var reviewQueueItem: ReviewQueueItemResponse
    var type: String = "moderation.custom_action"

    init(actionId: String, actionOptions: [String: RawJSON]? = nil, createdAt: Date, custom: [String: RawJSON], message: MessageResponse? = nil, receivedAt: Date? = nil, reviewQueueItem: ReviewQueueItemResponse) {
        self.actionId = actionId
        self.actionOptions = actionOptions
        self.createdAt = createdAt
        self.custom = custom
        self.message = message
        self.receivedAt = receivedAt
        self.reviewQueueItem = reviewQueueItem
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionId = "action_id"
        case actionOptions = "action_options"
        case createdAt = "created_at"
        case custom
        case message
        case receivedAt = "received_at"
        case reviewQueueItem = "review_queue_item"
        case type
    }

    static func == (lhs: ModerationCustomActionEvent, rhs: ModerationCustomActionEvent) -> Bool {
        lhs.actionId == rhs.actionId &&
            lhs.actionOptions == rhs.actionOptions &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.message == rhs.message &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.reviewQueueItem == rhs.reviewQueueItem &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionId)
        hasher.combine(actionOptions)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(message)
        hasher.combine(receivedAt)
        hasher.combine(reviewQueueItem)
        hasher.combine(type)
    }
}
