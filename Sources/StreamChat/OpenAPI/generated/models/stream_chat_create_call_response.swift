//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCreateCallResponse: Codable, Hashable {
    public var call: StreamChatCall?
    
    public var duration: String
    
    public var token: String
    
    public var agoraAppId: String?
    
    public var agoraUid: Int?
    
    public init(call: StreamChatCall?, duration: String, token: String, agoraAppId: String?, agoraUid: Int?) {
        self.call = call
        
        self.duration = duration
        
        self.token = token
        
        self.agoraAppId = agoraAppId
        
        self.agoraUid = agoraUid
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        
        case duration
        
        case token
        
        case agoraAppId = "agora_app_id"
        
        case agoraUid = "agora_uid"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(token, forKey: .token)
        
        try container.encode(agoraAppId, forKey: .agoraAppId)
        
        try container.encode(agoraUid, forKey: .agoraUid)
    }
}
