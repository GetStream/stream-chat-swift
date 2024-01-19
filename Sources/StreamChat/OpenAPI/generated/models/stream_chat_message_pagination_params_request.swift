//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessagePaginationParamsRequest: Codable, Hashable {
    public var createdAtAfterOrEqual: Date?
    
    public var createdAtAround: Date?
    
    public var createdAtBeforeOrEqual: Date?
    
    public var idAround: String?
    
    public var idLte: String?
    
    public var limit: Int?
    
    public var createdAtAfter: Date?
    
    public var createdAtBefore: Date?
    
    public var idGt: String?
    
    public var idGte: String?
    
    public var idLt: String?
    
    public var offset: Int?
    
    public init(createdAtAfterOrEqual: Date?, createdAtAround: Date?, createdAtBeforeOrEqual: Date?, idAround: String?, idLte: String?, limit: Int?, createdAtAfter: Date?, createdAtBefore: Date?, idGt: String?, idGte: String?, idLt: String?, offset: Int?) {
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtAround = createdAtAround
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.idAround = idAround
        
        self.idLte = idLte
        
        self.limit = limit
        
        self.createdAtAfter = createdAtAfter
        
        self.createdAtBefore = createdAtBefore
        
        self.idGt = idGt
        
        self.idGte = idGte
        
        self.idLt = idLt
        
        self.offset = offset
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtAround = "created_at_around"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case idAround = "id_around"
        
        case idLte = "id_lte"
        
        case limit
        
        case createdAtAfter = "created_at_after"
        
        case createdAtBefore = "created_at_before"
        
        case idGt = "id_gt"
        
        case idGte = "id_gte"
        
        case idLt = "id_lt"
        
        case offset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtAround, forKey: .createdAtAround)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(idAround, forKey: .idAround)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(offset, forKey: .offset)
    }
}
