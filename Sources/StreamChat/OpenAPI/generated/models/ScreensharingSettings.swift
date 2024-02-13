//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ScreensharingSettings: Codable, Hashable {
    public var accessRequestEnabled: Bool
    public var enabled: Bool

    public init(accessRequestEnabled: Bool, enabled: Bool) {
        self.accessRequestEnabled = accessRequestEnabled
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case enabled
    }
}
