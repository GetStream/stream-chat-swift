//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MuteUserResponse: Codable, Hashable {
    public var duration: String
    public var mutes: [UserMute?]? = nil
    public var nonExistingUsers: [String]? = nil
    public var mute: UserMute? = nil
    public var ownUser: OwnUser? = nil

    public init(duration: String, mutes: [UserMute?]? = nil, nonExistingUsers: [String]? = nil, mute: UserMute? = nil, ownUser: OwnUser? = nil) {
        self.duration = duration
        self.mutes = mutes
        self.nonExistingUsers = nonExistingUsers
        self.mute = mute
        self.ownUser = ownUser
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case mutes
        case nonExistingUsers = "non_existing_users"
        case mute
        case ownUser = "own_user"
    }
}
