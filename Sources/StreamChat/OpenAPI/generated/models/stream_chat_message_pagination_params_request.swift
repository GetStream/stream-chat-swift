//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessagePaginationParamsRequest: Codable, Hashable {
    public var idLt: String?
    
    public var idLte: String?
    
    public var limit: Int?
    
    public var offset: Int?
    
    public var createdAtAfter: Date?
    
    public var createdAtAround: Date?
    
    public var createdAtBefore: Date?
    
    public var idGt: String?
    
    public var idGte: String?
    
    public var createdAtAfterOrEqual: Date?
    
    public var createdAtBeforeOrEqual: Date?
    
    public var idAround: String?
    
    public init(idLt: String?, idLte: String?, limit: Int?, offset: Int?, createdAtAfter: Date?, createdAtAround: Date?, createdAtBefore: Date?, idGt: String?, idGte: String?, createdAtAfterOrEqual: Date?, createdAtBeforeOrEqual: Date?, idAround: String?) {
        self.idLt = idLt
        
        self.idLte = idLte
        
        self.limit = limit
        
        self.offset = offset
        
        self.createdAtAfter = createdAtAfter
        
        self.createdAtAround = createdAtAround
        
        self.createdAtBefore = createdAtBefore
        
        self.idGt = idGt
        
        self.idGte = idGte
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.idAround = idAround
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case idLt = "id_lt"
        
        case idLte = "id_lte"
        
        case limit
        
        case offset
        
        case createdAtAfter = "created_at_after"
        
        case createdAtAround = "created_at_around"
        
        case createdAtBefore = "created_at_before"
        
        case idGt = "id_gt"
        
        case idGte = "id_gte"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case idAround = "id_around"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtAround, forKey: .createdAtAround)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(idAround, forKey: .idAround)
    }
}
