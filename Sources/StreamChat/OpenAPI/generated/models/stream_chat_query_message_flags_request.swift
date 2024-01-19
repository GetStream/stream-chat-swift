//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMessageFlagsRequest: Codable, Hashable {
    public var showDeletedMessages: Bool?
    
    public var sort: [StreamChatSortParam?]?
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public var filterConditions: [String: RawJSON]?
    
    public var limit: Int?
    
    public var offset: Int?
    
    public init(showDeletedMessages: Bool?, sort: [StreamChatSortParam?]?, user: StreamChatUserObject?, userId: String?, filterConditions: [String: RawJSON]?, limit: Int?, offset: Int?) {
        self.showDeletedMessages = showDeletedMessages
        
        self.sort = sort
        
        self.user = user
        
        self.userId = userId
        
        self.filterConditions = filterConditions
        
        self.limit = limit
        
        self.offset = offset
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case showDeletedMessages = "show_deleted_messages"
        
        case sort
        
        case user
        
        case userId = "user_id"
        
        case filterConditions = "filter_conditions"
        
        case limit
        
        case offset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(showDeletedMessages, forKey: .showDeletedMessages)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
    }
}
