//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageActionRequest: Codable, Hashable {
    public var userId: String?
    
    public var iD: String?
    
    public var formData: [String: RawJSON]
    
    public var user: StreamChatUserObjectRequest?
    
    public init(userId: String?, iD: String?, formData: [String: RawJSON], user: StreamChatUserObjectRequest?) {
        self.userId = userId
        
        self.iD = iD
        
        self.formData = formData
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case iD = "ID"
        
        case formData = "form_data"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(iD, forKey: .iD)
        
        try container.encode(formData, forKey: .formData)
        
        try container.encode(user, forKey: .user)
    }
}
