//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessagePaginationParams: Sendable, Encodable, JSONEncodable {
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
        idAround: String? = nil,
        idGt: String? = nil,
        idGte: String? = nil,
        idLt: String? = nil,
        idLte: String? = nil,
        limit: Int? = nil
    ) {
        self.idAround = idAround
        self.idGt = idGt
        self.idGte = idGte
        self.idLt = idLt
        self.idLte = idLte
        self.limit = limit
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(idAround, forKey: .idAround)
        try container.encodeIfPresent(idGt, forKey: .idGt)
        try container.encodeIfPresent(idGte, forKey: .idGte)
        try container.encodeIfPresent(idLt, forKey: .idLt)
        try container.encodeIfPresent(idLte, forKey: .idLte)
        try container.encodeIfPresent(limit, forKey: .limit)
    }
}
