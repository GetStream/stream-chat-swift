//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PushNotificationSettingsRequest: Codable, Hashable {
    public var disabled: NullBoolRequest? = nil
    public var disabledUntil: NullTimeRequest? = nil

    public init(disabled: NullBoolRequest? = nil, disabledUntil: NullTimeRequest? = nil) {
        self.disabled = disabled
        self.disabledUntil = disabledUntil
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case disabled
        case disabledUntil = "disabled_until"
    }
}
