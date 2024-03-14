//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateUserPartialRequest: Codable, Hashable {
    public var id: String
    public var unset: [String]? = nil
    public var set: [String: RawJSON]? = nil

    public init(id: String, unset: [String]? = nil, set: [String: RawJSON]? = nil) {
        self.id = id
        self.unset = unset
        self.set = set
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case unset
        case set
    }
}
