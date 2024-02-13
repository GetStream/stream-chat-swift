//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PendingMessage: Codable, Hashable {
    public var channel: Channel? = nil
    public var message: Message? = nil
    public var metadata: [String: String]? = nil
    public var user: UserObject? = nil

    public init(channel: Channel? = nil, message: Message? = nil, metadata: [String: String]? = nil, user: UserObject? = nil) {
        self.channel = channel
        self.message = message
        self.metadata = metadata
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case message
        case metadata
        case user
    }
}
