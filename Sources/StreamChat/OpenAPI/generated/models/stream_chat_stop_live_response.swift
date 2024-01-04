//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatStopLiveResponse: Codable, Hashable {
    public var call: StreamChatCallResponse
    
    public var duration: String
    
    public init(call: StreamChatCallResponse, duration: String) {
        self.call = call
        
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(call, forKey: .call)
        
        try container.encode(duration, forKey: .duration)
    }
}
