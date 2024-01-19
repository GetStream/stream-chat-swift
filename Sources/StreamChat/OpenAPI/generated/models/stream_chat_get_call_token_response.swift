//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetCallTokenResponse: Codable, Hashable {
    public var agoraAppId: String?
    
    public var agoraUid: Int?
    
    public var duration: String
    
    public var token: String
    
    public init(agoraAppId: String?, agoraUid: Int?, duration: String, token: String) {
        self.agoraAppId = agoraAppId
        
        self.agoraUid = agoraUid
        
        self.duration = duration
        
        self.token = token
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case agoraAppId = "agora_app_id"
        
        case agoraUid = "agora_uid"
        
        case duration
        
        case token
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(agoraAppId, forKey: .agoraAppId)
        
        try container.encode(agoraUid, forKey: .agoraUid)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(token, forKey: .token)
    }
}