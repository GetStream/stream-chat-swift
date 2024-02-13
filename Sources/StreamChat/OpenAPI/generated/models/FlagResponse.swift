//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FlagResponse: Codable, Hashable {
    public var duration: String
    public var flag: Flag? = nil

    public init(duration: String, flag: Flag? = nil) {
        self.duration = duration
        self.flag = flag
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case flag
    }
}
