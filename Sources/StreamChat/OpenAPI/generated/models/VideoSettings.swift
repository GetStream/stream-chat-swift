//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct VideoSettings: Codable, Hashable {
    public var accessRequestEnabled: Bool
    public var cameraDefaultOn: Bool
    public var cameraFacing: String
    public var enabled: Bool
    public var targetResolution: TargetResolution

    public init(accessRequestEnabled: Bool, cameraDefaultOn: Bool, cameraFacing: String, enabled: Bool, targetResolution: TargetResolution) {
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
}