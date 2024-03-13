//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateThreadPartialRequest: Codable, Hashable {
    public var unset: [String]
    public var set: [String: RawJSON]
    public var iD: String? = nil

    public init(unset: [String], set: [String: RawJSON], iD: String? = nil) {
        self.unset = unset
        self.set = set
        self.iD = iD
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unset
        case set
        case iD = "ID"
    }
}
