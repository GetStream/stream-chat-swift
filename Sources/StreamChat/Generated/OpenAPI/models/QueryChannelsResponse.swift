//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryChannelsResponse: Sendable, Decodable {
    /// List of channels
    let channels: [ChannelStateResponse]
    let predefinedFilter: ParsedPredefinedFilterResponse?

    init(channels: [ChannelStateResponse], predefinedFilter: ParsedPredefinedFilterResponse? = nil) {
        self.channels = channels
        self.predefinedFilter = predefinedFilter
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channels
        case predefinedFilter = "predefined_filter"
    }
}
