//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessagePaginationParamsRequest: Codable, Hashable {
    public var limit: Int?
    
    public var createdAtAround: String?
    
    public var idAround: String?
    
    public var idGt: String?
    
    public var createdAtBeforeOrEqual: String?
    
    public var idGte: String?
    
    public var idLt: String?
    
    public var idLte: String?
    
    public var offset: Int?
    
    public var createdAtAfter: String?
    
    public var createdAtAfterOrEqual: String?
    
    public var createdAtBefore: String?
    
    public init(limit: Int?, createdAtAround: String?, idAround: String?, idGt: String?, createdAtBeforeOrEqual: String?, idGte: String?, idLt: String?, idLte: String?, offset: Int?, createdAtAfter: String?, createdAtAfterOrEqual: String?, createdAtBefore: String?) {
        self.limit = limit
        
        self.createdAtAround = createdAtAround
        
        self.idAround = idAround
        
        self.idGt = idGt
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.idGte = idGte
        
        self.idLt = idLt
        
        self.idLte = idLte
        
        self.offset = offset
        
        self.createdAtAfter = createdAtAfter
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBefore = createdAtBefore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        
        case createdAtAround = "created_at_around"
        
        case idAround = "id_around"
        
        case idGt = "id_gt"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case idGte = "id_gte"
        
        case idLt = "id_lt"
        
        case idLte = "id_lte"
        
        case offset
        
        case createdAtAfter = "created_at_after"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBefore = "created_at_before"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(createdAtAround, forKey: .createdAtAround)
        
        try container.encode(idAround, forKey: .idAround)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
    }
}
