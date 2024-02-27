//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PaginationParamsRequest: Codable, Hashable {
    public var idGt: Int? = nil
    public var idGte: Int? = nil
    public var idLt: Int? = nil
    public var idLte: Int? = nil
    public var limit: Int? = nil
    public var offset: Int? = nil

    public init(idGt: Int? = nil, idGte: Int? = nil, idLt: Int? = nil, idLte: Int? = nil, limit: Int? = nil, offset: Int? = nil) {
        self.idGt = idGt
        self.idGte = idGte
        self.idLt = idLt
        self.idLte = idLte
        self.limit = limit
        self.offset = offset
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case idGt = "id_gt"
        case idGte = "id_gte"
        case idLt = "id_lt"
        case idLte = "id_lte"
        case limit
        case offset
    }
}