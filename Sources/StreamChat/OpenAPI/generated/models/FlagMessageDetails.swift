//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FlagMessageDetails: Codable, Hashable {
    public var pinChanged: Bool? = nil
    public var shouldEnrich: Bool? = nil
    public var skipPush: Bool? = nil
    public var updatedById: String? = nil

    public init(pinChanged: Bool? = nil, shouldEnrich: Bool? = nil, skipPush: Bool? = nil, updatedById: String? = nil) {
        self.pinChanged = pinChanged
        self.shouldEnrich = shouldEnrich
        self.skipPush = skipPush
        self.updatedById = updatedById
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pinChanged = "pin_changed"
        case shouldEnrich = "should_enrich"
        case skipPush = "skip_push"
        case updatedById = "updated_by_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pinChanged, forKey: .pinChanged)
        try container.encode(shouldEnrich, forKey: .shouldEnrich)
        try container.encode(skipPush, forKey: .skipPush)
        try container.encode(updatedById, forKey: .updatedById)
    }
}
