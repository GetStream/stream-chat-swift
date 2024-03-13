//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateChannelPartialRequest: Codable, Hashable {
    public var unset: [String]
    public var set: [String: RawJSON]

    public init(unset: [String], set: [String: RawJSON]) {
        self.unset = unset
        self.set = set
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unset
        case set
    }
}
