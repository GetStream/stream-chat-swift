//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateUserPermissionsRequest: Codable, Hashable {
    public var grantPermissions: [String]?
    
    public var revokePermissions: [String]?
    
    public var userId: String
    
    public init(grantPermissions: [String]?, revokePermissions: [String]?, userId: String) {
        self.grantPermissions = grantPermissions
        
        self.revokePermissions = revokePermissions
        
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case grantPermissions = "grant_permissions"
        
        case revokePermissions = "revoke_permissions"
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(grantPermissions, forKey: .grantPermissions)
        
        try container.encode(revokePermissions, forKey: .revokePermissions)
        
        try container.encode(userId, forKey: .userId)
    }
}
