//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ScreensharingSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var accessRequestEnabled: Bool
    var enabled: Bool
    var targetResolution: TargetResolution?

    init(accessRequestEnabled: Bool, enabled: Bool, targetResolution: TargetResolution? = nil) {
        self.accessRequestEnabled = accessRequestEnabled
        self.enabled = enabled
        self.targetResolution = targetResolution
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case enabled
        case targetResolution = "target_resolution"
    }

    static func == (lhs: ScreensharingSettingsResponse, rhs: ScreensharingSettingsResponse) -> Bool {
        lhs.accessRequestEnabled == rhs.accessRequestEnabled &&
            lhs.enabled == rhs.enabled &&
            lhs.targetResolution == rhs.targetResolution
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(accessRequestEnabled)
        hasher.combine(enabled)
        hasher.combine(targetResolution)
    }
}
