//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEgressHLSResponse: Codable, Hashable {
    public var playlistUrl: String
    
    public init(playlistUrl: String) {
        self.playlistUrl = playlistUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case playlistUrl = "playlist_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(playlistUrl, forKey: .playlistUrl)
    }
}
