//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageActionRequest: Codable, Hashable {
    public var iD: String?
    
    public var formData: [String: RawJSON]
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public init(iD: String?, formData: [String: RawJSON], user: StreamChatUserObjectRequest?, userId: String?) {
        self.iD = iD
        
        self.formData = formData
        
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case iD = "ID"
        
        case formData = "form_data"
        
        case user
        
        case userId = "user_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(iD, forKey: .iD)
        
        try container.encode(formData, forKey: .formData)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}
