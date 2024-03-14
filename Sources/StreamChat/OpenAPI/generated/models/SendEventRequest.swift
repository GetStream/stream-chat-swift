//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SendEventRequest: Codable, Hashable {
    public var event: EventRequest

    public init(event: EventRequest) {
        self.event = event
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case event
    }
}