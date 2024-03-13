//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GetThreadResponse: Codable, Hashable {
    public var duration: String
    public var thread: ThreadStateResponse? = nil

    public init(duration: String, thread: ThreadStateResponse? = nil) {
        self.duration = duration
        self.thread = thread
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case thread
    }
}
