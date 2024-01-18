//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryUsersRequest: Codable, Hashable {
    public var idGte: String?
    
    public var idLt: String?
    
    public var idLte: String?
    
    public var offset: Int?
    
    public var presence: Bool?
    
    public var sort: [StreamChatSortParam?]?
    
    public var filterConditions: [String: RawJSON]
    
    public var idGt: String?
    
    public var userId: String?
    
    public var user: StreamChatUserObject?
    
    public var connectionId: String?
    
    public var limit: Int?
    
    public init(idGte: String?, idLt: String?, idLte: String?, offset: Int?, presence: Bool?, sort: [StreamChatSortParam?]?, filterConditions: [String: RawJSON], idGt: String?, userId: String?, user: StreamChatUserObject?, connectionId: String?, limit: Int?) {
        self.idGte = idGte
        
        self.idLt = idLt
        
        self.idLte = idLte
        
        self.offset = offset
        
        self.presence = presence
        
        self.sort = sort
        
        self.filterConditions = filterConditions
        
        self.idGt = idGt
        
        self.userId = userId
        
        self.user = user
        
        self.connectionId = connectionId
        
        self.limit = limit
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case idGte = "id_gte"
        
        case idLt = "id_lt"
        
        case idLte = "id_lte"
        
        case offset
        
        case presence
        
        case sort
        
        case filterConditions = "filter_conditions"
        
        case idGt = "id_gt"
        
        case userId = "user_id"
        
        case user
        
        case connectionId = "connection_id"
        
        case limit
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(limit, forKey: .limit)
    }
}
