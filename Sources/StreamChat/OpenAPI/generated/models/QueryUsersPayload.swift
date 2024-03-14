//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryUsersPayload: Codable, Hashable {
    public var filterConditions: [String: RawJSON]
    public var connectionId: String? = nil
    public var idGt: String? = nil
    public var idGte: String? = nil
    public var idLt: String? = nil
    public var idLte: String? = nil
    public var includeDeactivatedUsers: Bool? = nil
    public var limit: Int? = nil
    public var offset: Int? = nil
    public var presence: Bool? = nil
    public var sort: [SortParam?]? = nil

    public init(filterConditions: [String: RawJSON], connectionId: String? = nil, idGt: String? = nil, idGte: String? = nil, idLt: String? = nil, idLte: String? = nil, includeDeactivatedUsers: Bool? = nil, limit: Int? = nil, offset: Int? = nil, presence: Bool? = nil, sort: [SortParam?]? = nil) {
        self.filterConditions = filterConditions
        self.connectionId = connectionId
        self.idGt = idGt
        self.idGte = idGte
        self.idLt = idLt
        self.idLte = idLte
        self.includeDeactivatedUsers = includeDeactivatedUsers
        self.limit = limit
        self.offset = offset
        self.presence = presence
        self.sort = sort
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case connectionId = "connection_id"
        case idGt = "id_gt"
        case idGte = "id_gte"
        case idLt = "id_lt"
        case idLte = "id_lte"
        case includeDeactivatedUsers = "include_deactivated_users"
        case limit
        case offset
        case presence
        case sort
    }
}
