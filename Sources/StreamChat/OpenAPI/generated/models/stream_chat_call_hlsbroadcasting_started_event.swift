//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallHLSBroadcastingStartedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var hlsPlaylistUrl: String
    
    public var type: String
    
    public var callCid: String
    
    public init(createdAt: String, hlsPlaylistUrl: String, type: String, callCid: String) {
        self.createdAt = createdAt
        
        self.hlsPlaylistUrl = hlsPlaylistUrl
        
        self.type = type
        
        self.callCid = callCid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case hlsPlaylistUrl = "hls_playlist_url"
        
        case type
        
        case callCid = "call_cid"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(hlsPlaylistUrl, forKey: .hlsPlaylistUrl)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(callCid, forKey: .callCid)
    }
}
