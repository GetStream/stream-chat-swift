//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPaginationParamsRequest: Codable, Hashable {
    public var idLt: Int?
    
    public var idLte: Int?
    
    public var limit: Int?
    
    public var offset: Int?
    
    public var idGt: Int?
    
    public var idGte: Int?
    
    public init(idLt: Int?, idLte: Int?, limit: Int?, offset: Int?, idGt: Int?, idGte: Int?) {
        self.idLt = idLt
        
        self.idLte = idLte
        
        self.limit = limit
        
        self.offset = offset
        
        self.idGt = idGt
        
        self.idGte = idGte
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case idLt = "id_lt"
        
        case idLte = "id_lte"
        
        case limit
        
        case offset
        
        case idGt = "id_gt"
        
        case idGte = "id_gte"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(idGte, forKey: .idGte)
    }
}
