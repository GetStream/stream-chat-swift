//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SearchWarning: Codable, Hashable {
    public var warningCode: Int
    public var warningDescription: String
    public var channelSearchCount: Int? = nil
    public var channelSearchCids: [String]? = nil

    public init(warningCode: Int, warningDescription: String, channelSearchCount: Int? = nil, channelSearchCids: [String]? = nil) {
        self.warningCode = warningCode
        self.warningDescription = warningDescription
        self.channelSearchCount = channelSearchCount
        self.channelSearchCids = channelSearchCids
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case warningCode = "warning_code"
        case warningDescription = "warning_description"
        case channelSearchCount = "channel_search_count"
        case channelSearchCids = "channel_search_cids"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(warningCode, forKey: .warningCode)
        try container.encode(warningDescription, forKey: .warningDescription)
        try container.encode(channelSearchCount, forKey: .channelSearchCount)
        try container.encode(channelSearchCids, forKey: .channelSearchCids)
    }
}
