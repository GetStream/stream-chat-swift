//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteUserResponse: Codable, Hashable {
    public var mutes: [StreamChatUserMute?]?
    
    public var nonExistingUsers: [String]?
    
    public var ownUser: StreamChatOwnUser?
    
    public var duration: String
    
    public var mute: StreamChatUserMute?
    
    public init(mutes: [StreamChatUserMute?]?, nonExistingUsers: [String]?, ownUser: StreamChatOwnUser?, duration: String, mute: StreamChatUserMute?) {
        self.mutes = mutes
        
        self.nonExistingUsers = nonExistingUsers
        
        self.ownUser = ownUser
        
        self.duration = duration
        
        self.mute = mute
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mutes
        
        case nonExistingUsers = "non_existing_users"
        
        case ownUser = "own_user"
        
        case duration
        
        case mute
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(nonExistingUsers, forKey: .nonExistingUsers)
        
        try container.encode(ownUser, forKey: .ownUser)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(mute, forKey: .mute)
    }
}
