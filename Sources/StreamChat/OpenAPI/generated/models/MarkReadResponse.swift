//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MarkReadResponse: Codable, Hashable {
    public var duration: String
    public var event: MessageReadEvent? = nil

    public init(duration: String, event: MessageReadEvent? = nil) {
        self.duration = duration
        self.event = event
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case event
    }
}
