//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryUsersRequest: Codable, Hashable {
    public var filterConditions: [String: RawJSON]
    public var connectionId: String? = nil
    public var idGt: String? = nil
    public var idGte: String? = nil
    public var idLt: String? = nil
    public var idLte: String? = nil
    public var limit: Int? = nil
    public var offset: Int? = nil
    public var presence: Bool? = nil
    public var userId: String? = nil
    public var sort: [SortParam?]? = nil
    public var user: UserObject? = nil

    public init(filterConditions: [String: RawJSON], connectionId: String? = nil, idGt: String? = nil, idGte: String? = nil, idLt: String? = nil, idLte: String? = nil, limit: Int? = nil, offset: Int? = nil, presence: Bool? = nil, userId: String? = nil, sort: [SortParam?]? = nil, user: UserObject? = nil) {
        self.filterConditions = filterConditions
        self.connectionId = connectionId
        self.idGt = idGt
        self.idGte = idGte
        self.idLt = idLt
        self.idLte = idLte
        self.limit = limit
        self.offset = offset
        self.presence = presence
        self.userId = userId
        self.sort = sort
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case connectionId = "connection_id"
        case idGt = "id_gt"
        case idGte = "id_gte"
        case idLt = "id_lt"
        case idLte = "id_lte"
        case limit
        case offset
        case presence
        case userId = "user_id"
        case sort
        case user
    }
}
