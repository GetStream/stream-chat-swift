//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchWarning: Sendable, Decodable {
    /// Channel CIDs for the searched channels
    let channelSearchCids: [String]?
    /// Number of channels searched
    let channelSearchCount: Int?
    /// Code corresponding to the warning
    let warningCode: Int
    /// Description of the warning
    let warningDescription: String

    init(
        channelSearchCids: [String]? = nil,
        channelSearchCount: Int? = nil,
        warningCode: Int,
        warningDescription: String
    ) {
        self.channelSearchCids = channelSearchCids
        self.channelSearchCount = channelSearchCount
        self.warningCode = warningCode
        self.warningDescription = warningDescription
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelSearchCids = "channel_search_cids"
        case channelSearchCount = "channel_search_count"
        case warningCode = "warning_code"
        case warningDescription = "warning_description"
    }
}
