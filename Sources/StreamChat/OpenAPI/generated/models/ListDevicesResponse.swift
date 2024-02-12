//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ListDevicesResponse: Codable, Hashable {
    public var duration: String
    
    public var devices: [PNDevice]
    
    public init(duration: String, devices: [PNDevice]) {
        self.duration = duration
        
        self.devices = devices
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case devices
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(devices, forKey: .devices)
    }
}
