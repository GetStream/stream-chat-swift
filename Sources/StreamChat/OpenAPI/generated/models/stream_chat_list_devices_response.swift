//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatListDevicesResponse: Codable, Hashable {
    public var devices: [StreamChatDevice?]
    
    public var duration: String
    
    public init(devices: [StreamChatDevice?], duration: String) {
        self.devices = devices
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case devices
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(devices, forKey: .devices)
        
        try container.encode(duration, forKey: .duration)
    }
}
