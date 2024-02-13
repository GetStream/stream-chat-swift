//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct EventResponse: Codable, Hashable {
    public var duration: String
    public var event: WSEvent

    public init(duration: String, event: WSEvent) {
        self.duration = duration
        self.event = event
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case event
    }
}
