//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryUsersRequest: Codable, Hashable {
    public var idLte: String?
    
    public var offset: Int?
    
    public var presence: Bool?
    
    public var connectionId: String?
    
    public var filterConditions: [String: RawJSON]
    
    public var idLt: String?
    
    public var sort: [StreamChatSortParam?]?
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public var idGt: String?
    
    public var idGte: String?
    
    public var limit: Int?
    
    public init(idLte: String?, offset: Int?, presence: Bool?, connectionId: String?, filterConditions: [String: RawJSON], idLt: String?, sort: [StreamChatSortParam?]?, user: StreamChatUserObject?, userId: String?, idGt: String?, idGte: String?, limit: Int?) {
        self.idLte = idLte
        
        self.offset = offset
        
        self.presence = presence
        
        self.connectionId = connectionId
        
        self.filterConditions = filterConditions
        
        self.idLt = idLt
        
        self.sort = sort
        
        self.user = user
        
        self.userId = userId
        
        self.idGt = idGt
        
        self.idGte = idGte
        
        self.limit = limit
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case idLte = "id_lte"
        
        case offset
        
        case presence
        
        case connectionId = "connection_id"
        
        case filterConditions = "filter_conditions"
        
        case idLt = "id_lt"
        
        case sort
        
        case user
        
        case userId = "user_id"
        
        case idGt = "id_gt"
        
        case idGte = "id_gte"
        
        case limit
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(limit, forKey: .limit)
    }
}
