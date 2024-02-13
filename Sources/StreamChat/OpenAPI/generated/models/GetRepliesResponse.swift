//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GetRepliesResponse: Codable, Hashable {
    public var duration: String
    public var messages: [Message]

    public init(duration: String, messages: [Message]) {
        self.duration = duration
        self.messages = messages
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case messages
    }
}
