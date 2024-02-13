//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StopWatchingResponse: Codable, Hashable {
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }
}
