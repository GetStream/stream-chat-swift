//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatVideoSettings: Codable, Hashable {
    public var accessRequestEnabled: Bool
    
    public var cameraDefaultOn: Bool
    
    public var cameraFacing: String
    
    public var enabled: Bool
    
    public var targetResolution: StreamChatTargetResolution
    
    public init(accessRequestEnabled: Bool, cameraDefaultOn: Bool, cameraFacing: String, enabled: Bool, targetResolution: StreamChatTargetResolution) {
        self.accessRequestEnabled = accessRequestEnabled
        
        self.cameraDefaultOn = cameraDefaultOn
        
        self.cameraFacing = cameraFacing
        
        self.enabled = enabled
        
        self.targetResolution = targetResolution
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        
        case cameraDefaultOn = "camera_default_on"
        
        case cameraFacing = "camera_facing"
        
        case enabled
        
        case targetResolution = "target_resolution"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(accessRequestEnabled, forKey: .accessRequestEnabled)
        
        try container.encode(cameraDefaultOn, forKey: .cameraDefaultOn)
        
        try container.encode(cameraFacing, forKey: .cameraFacing)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(targetResolution, forKey: .targetResolution)
    }
}
