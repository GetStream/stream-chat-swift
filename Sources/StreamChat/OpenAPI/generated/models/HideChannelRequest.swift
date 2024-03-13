//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct HideChannelRequest: Codable, Hashable {
    public var clearHistory: Bool? = nil

    public init(clearHistory: Bool? = nil) {
        self.clearHistory = clearHistory
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case clearHistory = "clear_history"
    }
}
