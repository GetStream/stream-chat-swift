//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBackstageSettingsRequest: Codable, Hashable {
    public var enabled: Bool?
    
    public init(enabled: Bool?) {
        self.enabled = enabled
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(enabled, forKey: .enabled)
    }
}
