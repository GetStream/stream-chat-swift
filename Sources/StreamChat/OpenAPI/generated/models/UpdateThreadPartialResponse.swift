//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateThreadPartialResponse: Codable, Hashable {
    public var duration: String
    public var thread: ThreadResponse? = nil

    public init(duration: String, thread: ThreadResponse? = nil) {
        self.duration = duration
        self.thread = thread
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case thread
    }
}
