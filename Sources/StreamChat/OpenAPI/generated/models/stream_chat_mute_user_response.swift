//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteUserResponse: Codable, Hashable {
    public var duration: String
    
    public var mute: StreamChatUserMute?
    
    public var mutes: [StreamChatUserMute?]?
    
    public var nonExistingUsers: [String]?
    
    public var ownUser: StreamChatOwnUser?
    
    public init(duration: String, mute: StreamChatUserMute?, mutes: [StreamChatUserMute?]?, nonExistingUsers: [String]?, ownUser: StreamChatOwnUser?) {
        self.duration = duration
        
        self.mute = mute
        
        self.mutes = mutes
        
        self.nonExistingUsers = nonExistingUsers
        
        self.ownUser = ownUser
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case mute
        
        case mutes
        
        case nonExistingUsers = "non_existing_users"
        
        case ownUser = "own_user"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(mute, forKey: .mute)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(nonExistingUsers, forKey: .nonExistingUsers)
        
        try container.encode(ownUser, forKey: .ownUser)
    }
}
