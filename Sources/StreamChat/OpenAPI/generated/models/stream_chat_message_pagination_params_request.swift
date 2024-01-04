//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessagePaginationParamsRequest: Codable, Hashable {
    public var limit: Int?
    
    public var offset: Int?
    
    public var createdAtBefore: String?
    
    public var createdAtBeforeOrEqual: String?
    
    public var idLt: String?
    
    public var idAround: String?
    
    public var idGt: String?
    
    public var idGte: String?
    
    public var idLte: String?
    
    public var createdAtAfter: String?
    
    public var createdAtAfterOrEqual: String?
    
    public var createdAtAround: String?
    
    public init(limit: Int?, offset: Int?, createdAtBefore: String?, createdAtBeforeOrEqual: String?, idLt: String?, idAround: String?, idGt: String?, idGte: String?, idLte: String?, createdAtAfter: String?, createdAtAfterOrEqual: String?, createdAtAround: String?) {
        self.limit = limit
        
        self.offset = offset
        
        self.createdAtBefore = createdAtBefore
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.idLt = idLt
        
        self.idAround = idAround
        
        self.idGt = idGt
        
        self.idGte = idGte
        
        self.idLte = idLte
        
        self.createdAtAfter = createdAtAfter
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtAround = createdAtAround
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        
        case offset
        
        case createdAtBefore = "created_at_before"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case idLt = "id_lt"
        
        case idAround = "id_around"
        
        case idGt = "id_gt"
        
        case idGte = "id_gte"
        
        case idLte = "id_lte"
        
        case createdAtAfter = "created_at_after"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtAround = "created_at_around"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(idAround, forKey: .idAround)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtAround, forKey: .createdAtAround)
    }
}
