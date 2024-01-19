//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatStartHLSBroadcastingResponse: Codable, Hashable {
    public var duration: String
    
    public var playlistUrl: String
    
    public init(duration: String, playlistUrl: String) {
        self.duration = duration
        
        self.playlistUrl = playlistUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case playlistUrl = "playlist_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(playlistUrl, forKey: .playlistUrl)
    }
}
