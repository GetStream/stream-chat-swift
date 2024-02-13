//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessagePaginationParamsRequest: Codable, Hashable {
    public var createdAtAfter: Date? = nil
    public var createdAtAfterOrEqual: Date? = nil
    public var createdAtAround: Date? = nil
    public var createdAtBefore: Date? = nil
    public var createdAtBeforeOrEqual: Date? = nil
    public var idAround: String? = nil
    public var idGt: String? = nil
    public var idGte: String? = nil
    public var idLt: String? = nil
    public var idLte: String? = nil
    public var limit: Int? = nil
    public var offset: Int? = nil

    public init(createdAtAfter: Date? = nil, createdAtAfterOrEqual: Date? = nil, createdAtAround: Date? = nil, createdAtBefore: Date? = nil, createdAtBeforeOrEqual: Date? = nil, idAround: String? = nil, idGt: String? = nil, idGte: String? = nil, idLt: String? = nil, idLte: String? = nil, limit: Int? = nil, offset: Int? = nil) {
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
        self.offset = offset
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
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
        case offset
    }
}
