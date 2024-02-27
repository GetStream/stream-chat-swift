//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct HideChannelRequest: Codable, Hashable {
    public var clearHistory: Bool? = nil
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(clearHistory: Bool? = nil, userId: String? = nil, user: UserObjectRequest? = nil) {
        self.clearHistory = clearHistory
        self.userId = userId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case clearHistory = "clear_history"
        case userId = "user_id"
        case user
    }
}