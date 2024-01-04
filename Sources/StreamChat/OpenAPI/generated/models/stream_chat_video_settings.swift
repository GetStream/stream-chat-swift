//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatVideoSettings: Codable, Hashable {
    public var cameraDefaultOn: Bool
    
    public var cameraFacing: String
    
    public var enabled: Bool
    
    public var targetResolution: StreamChatTargetResolution
    
    public var accessRequestEnabled: Bool
    
    public init(cameraDefaultOn: Bool, cameraFacing: String, enabled: Bool, targetResolution: StreamChatTargetResolution, accessRequestEnabled: Bool) {
        self.cameraDefaultOn = cameraDefaultOn
        
        self.cameraFacing = cameraFacing
        
        self.enabled = enabled
        
        self.targetResolution = targetResolution
        
        self.accessRequestEnabled = accessRequestEnabled
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cameraDefaultOn = "camera_default_on"
        
        case cameraFacing = "camera_facing"
        
        case enabled
        
        case targetResolution = "target_resolution"
        
        case accessRequestEnabled = "access_request_enabled"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cameraDefaultOn, forKey: .cameraDefaultOn)
        
        try container.encode(cameraFacing, forKey: .cameraFacing)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(targetResolution, forKey: .targetResolution)
        
        try container.encode(accessRequestEnabled, forKey: .accessRequestEnabled)
    }
}
