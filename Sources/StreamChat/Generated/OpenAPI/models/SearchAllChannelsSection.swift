//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchAllChannelsSection: Sendable, Decodable {
    /// Channels the caller is a member of whose name starts with the query, in the same shape as the query channels endpoint's results but without messages or members
    let channels: [ChannelStateResponse]?
    let error: SearchAllSectionError?
    /// Opaque cursor for the next page of this section, present only when more results exist. Pass it back under next.channels with the same query
    let next: String?
    let warning: SearchAllWarning?

    init(
        channels: [ChannelStateResponse]? = nil,
        error: SearchAllSectionError? = nil,
        next: String? = nil,
        warning: SearchAllWarning? = nil
    ) {
        self.channels = channels
        self.error = error
        self.next = next
        self.warning = warning
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channels = try container.decodeIfPresent([ChannelStateResponse].self, forKey: .channels)
        self.error = try container.decodeIfPresent(SearchAllSectionError.self, forKey: .error)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.warning = try container.decodeIfPresent(SearchAllWarning.self, forKey: .warning)
    }
}
