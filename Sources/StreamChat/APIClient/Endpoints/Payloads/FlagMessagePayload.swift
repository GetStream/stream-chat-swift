//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming JSON from `moderation/(un)flag` message endpoint.
struct FlagMessagePayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case flag
        case currentUser = "user"
        case flaggedMessageId = "target_message_id"
    }
    
    /// The payload of the current user who performed flag/unflag action.
    let currentUser: CurrentUserPayload
    /// The `id` of the message which was flagged or unflagged.
    let flaggedMessageId: MessageId
    
    init(from decoder: Decoder) throws {
        let nestedContainer = try decoder
            .container(keyedBy: CodingKeys.self)
            .nestedContainer(keyedBy: CodingKeys.self, forKey: .flag)
        
        self.init(
            currentUser: try nestedContainer.decode(CurrentUserPayload.self, forKey: .currentUser),
            flaggedMessageId: try nestedContainer.decode(MessageId.self, forKey: .flaggedMessageId)
        )
    }
    
    init(
        currentUser: CurrentUserPayload,
        flaggedMessageId: MessageId
    ) {
        self.currentUser = currentUser
        self.flaggedMessageId = flaggedMessageId
    }
}
