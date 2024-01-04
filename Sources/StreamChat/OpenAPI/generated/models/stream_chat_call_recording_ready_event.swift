//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallRecordingReadyEvent: Codable, Hashable {
    public var callCid: String
    
    public var callRecording: StreamChatCallRecording
    
    public var createdAt: String
    
    public var type: String
    
    public init(callCid: String, callRecording: StreamChatCallRecording, createdAt: String, type: String) {
        self.callCid = callCid
        
        self.callRecording = callRecording
        
        self.createdAt = createdAt
        
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        
        case callRecording = "call_recording"
        
        case createdAt = "created_at"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callCid, forKey: .callCid)
        
        try container.encode(callRecording, forKey: .callRecording)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
    }
}
