//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryChannelsResponse: Sendable, Decodable {
    /// List of channels
    let channels: [ChannelStateResponseFields]
    let predefinedFilter: ParsedPredefinedFilterResponse?

    init(
        channels: [ChannelStateResponseFields],
        predefinedFilter: ParsedPredefinedFilterResponse? = nil
    ) {
        self.channels = channels
        self.predefinedFilter = predefinedFilter
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channels = try container.decodeArrayIgnoringFailures(
            [ChannelStateResponseFields].self,
            forKey: .channels
        )
        self.predefinedFilter = try container.decodeIfPresent(
            ParsedPredefinedFilterResponse.self,
            forKey: .predefinedFilter
        )
    }
}
