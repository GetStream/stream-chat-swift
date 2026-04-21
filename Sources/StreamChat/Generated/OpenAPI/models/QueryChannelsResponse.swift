//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryChannelsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of channels
    var channels: [ChannelStateResponseFields]
    /// Duration of the request in milliseconds
    var duration: String
    var predefinedFilter: ParsedPredefinedFilterResponse?

    init(channels: [ChannelStateResponseFields], duration: String, predefinedFilter: ParsedPredefinedFilterResponse? = nil) {
        self.channels = channels
        self.duration = duration
        self.predefinedFilter = predefinedFilter
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channels
        case duration
        case predefinedFilter = "predefined_filter"
    }

    static func == (lhs: QueryChannelsResponse, rhs: QueryChannelsResponse) -> Bool {
        lhs.channels == rhs.channels &&
            lhs.duration == rhs.duration &&
            lhs.predefinedFilter == rhs.predefinedFilter
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channels)
        hasher.combine(duration)
        hasher.combine(predefinedFilter)
    }
}
