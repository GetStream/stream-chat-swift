//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryUsersRequest: Codable, Hashable {
    public var idGt: String?
    
    public var idGte: String?
    
    public var idLt: String?
    
    public var idLte: String?
    
    public var limit: Int?
    
    public var offset: Int?
    
    public var presence: Bool?
    
    public var user: StreamChatUserObject?
    
    public var connectionId: String?
    
    public var filterConditions: [String: RawJSON]
    
    public var sort: [StreamChatSortParam?]?
    
    public var userId: String?
    
    public init(idGt: String?, idGte: String?, idLt: String?, idLte: String?, limit: Int?, offset: Int?, presence: Bool?, user: StreamChatUserObject?, connectionId: String?, filterConditions: [String: RawJSON], sort: [StreamChatSortParam?]?, userId: String?) {
        self.idGt = idGt
        
        self.idGte = idGte
        
        self.idLt = idLt
        
        self.idLte = idLte
        
        self.limit = limit
        
        self.offset = offset
        
        self.presence = presence
        
        self.user = user
        
        self.connectionId = connectionId
        
        self.filterConditions = filterConditions
        
        self.sort = sort
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case idGt = "id_gt"
        
        case idGte = "id_gte"
        
        case idLt = "id_lt"
        
        case idLte = "id_lte"
        
        case limit
        
        case offset
        
        case presence
        
        case user
        
        case connectionId = "connection_id"
        
        case filterConditions = "filter_conditions"
        
        case sort
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(idGt, forKey: .idGt)
        
        try container.encode(idGte, forKey: .idGte)
        
        try container.encode(idLt, forKey: .idLt)
        
        try container.encode(idLte, forKey: .idLte)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(userId, forKey: .userId)
    }
}
