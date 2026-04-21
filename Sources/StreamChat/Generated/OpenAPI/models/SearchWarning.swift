//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchWarning: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Channel CIDs for the searched channels
    var channelSearchCids: [String]?
    /// Number of channels searched
    var channelSearchCount: Int?
    /// Code corresponding to the warning
    var warningCode: Int
    /// Description of the warning
    var warningDescription: String

    init(channelSearchCids: [String]? = nil, channelSearchCount: Int? = nil, warningCode: Int, warningDescription: String) {
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

    static func == (lhs: SearchWarning, rhs: SearchWarning) -> Bool {
        lhs.channelSearchCids == rhs.channelSearchCids &&
            lhs.channelSearchCount == rhs.channelSearchCount &&
            lhs.warningCode == rhs.warningCode &&
            lhs.warningDescription == rhs.warningDescription
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelSearchCids)
        hasher.combine(channelSearchCount)
        hasher.combine(warningCode)
        hasher.combine(warningDescription)
    }
}
