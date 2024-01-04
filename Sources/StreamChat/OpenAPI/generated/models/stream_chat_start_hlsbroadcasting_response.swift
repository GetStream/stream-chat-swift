//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatStartHLSBroadcastingResponse: Codable, Hashable {
    public var playlistUrl: String
    
    public var duration: String
    
    public init(playlistUrl: String, duration: String) {
        self.playlistUrl = playlistUrl
        
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case playlistUrl = "playlist_url"
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(playlistUrl, forKey: .playlistUrl)
        
        try container.encode(duration, forKey: .duration)
    }
}
