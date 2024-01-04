//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateCallMembersRequest: Codable, Hashable {
    public var removeMembers: [String]?
    
    public var updateMembers: [StreamChatMemberRequest]?
    
    public init(removeMembers: [String]?, updateMembers: [StreamChatMemberRequest]?) {
        self.removeMembers = removeMembers
        
        self.updateMembers = updateMembers
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case removeMembers = "remove_members"
        
        case updateMembers = "update_members"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(removeMembers, forKey: .removeMembers)
        
        try container.encode(updateMembers, forKey: .updateMembers)
    }
}
