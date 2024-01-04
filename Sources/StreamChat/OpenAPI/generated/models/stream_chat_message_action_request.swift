//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageActionRequest: Codable, Hashable {
    public var formData: [String: RawJSON]
    
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public var iD: String?
    
    public init(formData: [String: RawJSON], user: StreamChatUserObjectRequest?, userId: String?, iD: String?) {
        self.formData = formData
        
        self.user = user
        
        self.userId = userId
        
        self.iD = iD
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case formData = "form_data"
        
        case user
        
        case userId = "user_id"
        
        case iD = "ID"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(formData, forKey: .formData)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(iD, forKey: .iD)
    }
}
