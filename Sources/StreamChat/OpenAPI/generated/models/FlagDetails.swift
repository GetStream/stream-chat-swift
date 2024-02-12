//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FlagDetails: Codable, Hashable {
    public var originalText: String
    public var extra: [String: RawJSON]
    public var automod: AutomodDetails? = nil

    public init(originalText: String, extra: [String: RawJSON], automod: AutomodDetails? = nil) {
        self.originalText = originalText
        self.extra = extra
        self.automod = automod
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case originalText = "original_text"
        case extra = "Extra"
        case automod
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(originalText, forKey: .originalText)
        try container.encode(extra, forKey: .extra)
        try container.encode(automod, forKey: .automod)
    }
}
