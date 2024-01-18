//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMessageFlagsRequest: Codable, Hashable {
    public var filterConditions: [String: RawJSON]?
    
    public var limit: Int?
    
    public var offset: Int?
    
    public var showDeletedMessages: Bool?
    
    public var sort: [StreamChatSortParam?]?
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public init(filterConditions: [String: RawJSON]?, limit: Int?, offset: Int?, showDeletedMessages: Bool?, sort: [StreamChatSortParam?]?, user: StreamChatUserObject?, userId: String?) {
        self.filterConditions = filterConditions
        
        self.limit = limit
        
        self.offset = offset
        
        self.showDeletedMessages = showDeletedMessages
        
        self.sort = sort
        
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        
        case limit
        
        case offset
        
        case showDeletedMessages = "show_deleted_messages"
        
        case sort
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(showDeletedMessages, forKey: .showDeletedMessages)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}
