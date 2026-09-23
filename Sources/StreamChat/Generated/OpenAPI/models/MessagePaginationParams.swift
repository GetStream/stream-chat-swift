//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessagePaginationParams: Sendable, Encodable, JSONEncodable {
    /// The timestamp to get messages with a created_at timestamp greater than
    let createdAtAfter: Date?
    /// The timestamp to get messages with a created_at timestamp greater than or equal to
    let createdAtAfterOrEqual: Date?
    /// The result will be a set of messages, that are both older and newer than the created_at timestamp provided, distributed evenly around the timestamp
    let createdAtAround: Date?
    /// The timestamp to get messages with a created_at timestamp smaller than
    let createdAtBefore: Date?
    /// The timestamp to get messages with a created_at timestamp smaller than or equal to
    let createdAtBeforeOrEqual: Date?
    /// The result will be a set of messages, that are both older and newer than the message with the provided ID, and the message with the ID provided will be in the middle of the set
    let idAround: String?
    /// The ID of the message to get messages with a timestamp greater than
    let idGt: String?
    /// The ID of the message to get messages with a timestamp greater than or equal to
    let idGte: String?
    /// The ID of the message to get messages with a timestamp smaller than
    let idLt: String?
    /// The ID of the message to get messages with a timestamp smaller than or equal to
    let idLte: String?
    /// The maximum number of messages to return (max limit
    let limit: Int?

    init(
        createdAtAfter: Date? = nil,
        createdAtAfterOrEqual: Date? = nil,
        createdAtAround: Date? = nil,
        createdAtBefore: Date? = nil,
        createdAtBeforeOrEqual: Date? = nil,
        idAround: String? = nil,
        idGt: String? = nil,
        idGte: String? = nil,
        idLt: String? = nil,
        idLte: String? = nil,
        limit: Int? = nil
    ) {
        self.createdAtAfter = createdAtAfter
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        self.createdAtAround = createdAtAround
        self.createdAtBefore = createdAtBefore
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        self.idAround = idAround
        self.idGt = idGt
        self.idGte = idGte
        self.idLt = idLt
        self.idLte = idLte
        self.limit = limit
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtAfter = "created_at_after"
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        case createdAtAround = "created_at_around"
        case createdAtBefore = "created_at_before"
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        case idAround = "id_around"
        case idGt = "id_gt"
        case idGte = "id_gte"
        case idLt = "id_lt"
        case idLte = "id_lte"
        case limit
    }
}
