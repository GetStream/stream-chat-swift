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
}
