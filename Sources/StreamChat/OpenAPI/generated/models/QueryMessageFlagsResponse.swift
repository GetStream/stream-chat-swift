//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryMessageFlagsResponse: Codable, Hashable {
    public var duration: String
    public var flags: [MessageFlag?]

    public init(duration: String, flags: [MessageFlag?]) {
        self.duration = duration
        self.flags = flags
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case flags
    }
}
