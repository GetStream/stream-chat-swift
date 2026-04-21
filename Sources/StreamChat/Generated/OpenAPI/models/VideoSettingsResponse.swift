//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class VideoSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var accessRequestEnabled: Bool
    var cameraDefaultOn: Bool
    var cameraFacing: String
    var enabled: Bool
    var targetResolution: TargetResolution

    init(accessRequestEnabled: Bool, cameraDefaultOn: Bool, cameraFacing: String, enabled: Bool, targetResolution: TargetResolution) {
        self.accessRequestEnabled = accessRequestEnabled
        self.cameraDefaultOn = cameraDefaultOn
        self.cameraFacing = cameraFacing
        self.enabled = enabled
        self.targetResolution = targetResolution
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case cameraDefaultOn = "camera_default_on"
        case cameraFacing = "camera_facing"
        case enabled
        case targetResolution = "target_resolution"
    }

    static func == (lhs: VideoSettingsResponse, rhs: VideoSettingsResponse) -> Bool {
        lhs.accessRequestEnabled == rhs.accessRequestEnabled &&
            lhs.cameraDefaultOn == rhs.cameraDefaultOn &&
            lhs.cameraFacing == rhs.cameraFacing &&
            lhs.enabled == rhs.enabled &&
            lhs.targetResolution == rhs.targetResolution
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(accessRequestEnabled)
        hasher.combine(cameraDefaultOn)
        hasher.combine(cameraFacing)
        hasher.combine(enabled)
        hasher.combine(targetResolution)
    }
}
