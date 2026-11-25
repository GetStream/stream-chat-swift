//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchAllResponse: Sendable, Decodable {
    let channels: SearchAllChannelsSection?
    let messages: SearchAllMessagesSection?
    let users: SearchAllUsersSection?

    init(
        channels: SearchAllChannelsSection? = nil,
        messages: SearchAllMessagesSection? = nil,
        users: SearchAllUsersSection? = nil
    ) {
        self.channels = channels
        self.messages = messages
        self.users = users
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channels = try container.decodeIfPresent(
            SearchAllChannelsSection.self,
            forKey: .channels
        )
        self.messages = try container.decodeIfPresent(
            SearchAllMessagesSection.self,
            forKey: .messages
        )
        self.users = try container.decodeIfPresent(SearchAllUsersSection.self, forKey: .users)
    }
}
