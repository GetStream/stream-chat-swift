//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PushNotificationSettings: Codable, Hashable {
    public var disabled: Bool? = nil
    public var disabledUntil: Date? = nil

    public init(disabled: Bool? = nil, disabledUntil: Date? = nil) {
        self.disabled = disabled
        self.disabledUntil = disabledUntil
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case disabled
        case disabledUntil = "disabled_until"
    }
}
