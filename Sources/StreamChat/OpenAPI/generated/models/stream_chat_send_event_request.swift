//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSendEventRequest: Codable, Hashable {
    public var event: StreamChatEventRequest
    
    public init(event: StreamChatEventRequest) {
        self.event = event
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case event
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(event, forKey: .event)
    }
}
