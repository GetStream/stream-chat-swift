//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessagePaginationParamsRequest: Codable, Hashable {
    public var createdAtBeforeOrEqual: String?
    
    public var idGt: String?
    
    public var idGte: String?
    
    public var idLt: String?
    
    public var createdAtAfter: String?
    
    public var createdAtAfterOrEqual: String?
    
    public var createdAtAround: String?
    
    public var limit: Int?
    
    public var offset: Int?
    
    public var createdAtBefore: String?
    
    public var idAround: String?
    
    public var idLte: String?
    
    public init(createdAtBeforeOrEqual: String?, idGt: String?, idGte: String?, idLt: String?, createdAtAfter: String?, createdAtAfterOrEqual: String?, createdAtAround: String?, limit: Int?, offset: Int?, createdAtBefore: String?, idAround: String?, idLte: String?) {
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.idGt = idGt
        
        self.idGte = idGte
        
        self.idLt = idLt
        
        self.createdAtAfter = createdAtAfter
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtAround = createdAtAround
        
        self.limit = limit
        
        self.offset = offset
        
        self.createdAtBefore = createdAtBefore
        
        self.idAround = idAround
        
        self.idLte = idLte
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case idGt = "id_gt"
        
        case idGte = "id_gte"
        
        case idLt = "id_lt"
        
        case createdAtAfter = "created_at_after"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtAround = "created_at_around"
        
        case limit
        
        case offset
        
        case createdAtBefore = "created_at_before"
        
        case idAround = "id_around"
        
        case idLte = "id_lte"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtAround, forKey: .createdAtAround)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(idAround, forKey: .idAround)
        
        try container.encode(idLte, forKey: .idLte)
    }
}
