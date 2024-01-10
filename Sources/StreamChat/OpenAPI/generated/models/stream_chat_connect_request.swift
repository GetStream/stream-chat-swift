//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatConnectRequest: Codable, Hashable {
    public var device: StreamChatDeviceFields?
    
    public var userDetails: StreamChatUserObject
    
    public init(device: StreamChatDeviceFields?, userDetails: StreamChatUserObject) {
        self.device = device
        
        self.userDetails = userDetails
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case device
        
        case userDetails = "user_details"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(device, forKey: .device)
        
        try container.encode(userDetails, forKey: .userDetails)
    }
}
