//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteUsersRequest: Codable, Hashable {
    public var muteAllUsers: Bool?
    
    public var screenshare: Bool?
    
    public var screenshareAudio: Bool?
    
    public var userIds: [String]?
    
    public var video: Bool?
    
    public var audio: Bool?
    
    public init(muteAllUsers: Bool?, screenshare: Bool?, screenshareAudio: Bool?, userIds: [String]?, video: Bool?, audio: Bool?) {
        self.muteAllUsers = muteAllUsers
        
        self.screenshare = screenshare
        
        self.screenshareAudio = screenshareAudio
        
        self.userIds = userIds
        
        self.video = video
        
        self.audio = audio
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case muteAllUsers = "mute_all_users"
        
        case screenshare
        
        case screenshareAudio = "screenshare_audio"
        
        case userIds = "user_ids"
        
        case video
        
        case audio
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(muteAllUsers, forKey: .muteAllUsers)
        
        try container.encode(screenshare, forKey: .screenshare)
        
        try container.encode(screenshareAudio, forKey: .screenshareAudio)
        
        try container.encode(userIds, forKey: .userIds)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(audio, forKey: .audio)
    }
}
