//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SyncResponse: Codable, Hashable {
    public var duration: String
    public var events: [WSEvent]
    public var inaccessibleCids: [String]? = nil

    public init(duration: String, events: [WSEvent], inaccessibleCids: [String]? = nil) {
        self.duration = duration
        self.events = events
        self.inaccessibleCids = inaccessibleCids
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case events
        case inaccessibleCids = "inaccessible_cids"
    }
}