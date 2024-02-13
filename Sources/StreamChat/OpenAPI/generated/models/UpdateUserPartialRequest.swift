//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateUserPartialRequest: Codable, Hashable {
    public var id: String
    public var unset: [String]
    public var set: [String: RawJSON]

    public init(id: String, unset: [String], set: [String: RawJSON]) {
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
