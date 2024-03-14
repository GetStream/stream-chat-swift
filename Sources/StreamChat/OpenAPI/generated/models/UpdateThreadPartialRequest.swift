//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateThreadPartialRequest: Codable, Hashable {
    public var iD: String? = nil
    public var unset: [String]? = nil
    public var set: [String: RawJSON]? = nil

    public init(iD: String? = nil, unset: [String]? = nil, set: [String: RawJSON]? = nil) {
        self.iD = iD
        self.unset = unset
        self.set = set
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case iD = "ID"
        case unset
        case set
    }
}
