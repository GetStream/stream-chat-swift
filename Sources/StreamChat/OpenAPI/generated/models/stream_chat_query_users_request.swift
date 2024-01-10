//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryUsersRequest: Codable, Hashable {
    public var offset: Int?
    
    public var sort: [StreamChatSortParam?]?
    
    public var connectionId: String?
    
    public var filterConditions: [String: RawJSON]
    
    public var idGt: String?
    
    public var idGte: String?
    
    public var idLte: String?
    
    public var limit: Int?
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public var idLt: String?
    
    public var presence: Bool?
    
    public init(offset: Int?, sort: [StreamChatSortParam?]?, connectionId: String?, filterConditions: [String: RawJSON], idGt: String?, idGte: String?, idLte: String?, limit: Int?, user: StreamChatUserObject?, userId: String?, idLt: String?, presence: Bool?) {
        self.offset = offset
        
        self.sort = sort
        
        self.connectionId = connectionId
        
        self.filterConditions = filterConditions
        
        self.idGt = idGt
        
        self.idGte = idGte
        
        self.idLte = idLte
        
        self.limit = limit
        
        self.user = user
        
        self.userId = userId
        
        self.idLt = idLt
        
        self.presence = presence
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case offset
        
        case sort
        
        case connectionId = "connection_id"
        
        case filterConditions = "filter_conditions"
        
        case idGt = "id_gt"
        
        case idGte = "id_gte"
        
        case idLte = "id_lte"
        
        case limit
        
        case user
        
        case userId = "user_id"
        
        case idLt = "id_lt"
        
        case presence
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(presence, forKey: .presence)
    }
}
