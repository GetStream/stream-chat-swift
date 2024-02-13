//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ReactionRemovalResponse: Codable, Hashable {
    public var duration: String
    public var message: Message? = nil
    public var reaction: Reaction? = nil

    public init(duration: String, message: Message? = nil, reaction: Reaction? = nil) {
        self.duration = duration
        self.message = message
        self.reaction = reaction
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case message
        case reaction
    }
}
