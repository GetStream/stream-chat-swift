//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryThreadsResponse: Codable, Hashable {
    public var duration: String
    public var threads: [ThreadStateResponse?]
    public var next: String? = nil
    public var prev: String? = nil

    public init(duration: String, threads: [ThreadStateResponse?], next: String? = nil, prev: String? = nil) {
        self.duration = duration
        self.threads = threads
        self.next = next
        self.prev = prev
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case threads
        case next
        case prev
    }
}
