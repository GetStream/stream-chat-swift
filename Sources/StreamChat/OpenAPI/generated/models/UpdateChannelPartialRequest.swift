//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateChannelPartialRequest: Codable, Hashable {
    public var unset: [String]? = nil
    public var set: [String: RawJSON]? = nil

    public init(unset: [String]? = nil, set: [String: RawJSON]? = nil) {
        self.unset = unset
        self.set = set
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unset
        case set
    }
}
