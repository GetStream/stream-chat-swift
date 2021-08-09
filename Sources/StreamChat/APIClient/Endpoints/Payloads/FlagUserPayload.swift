//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming JSON from `moderation/(un)flag` user endpoint.
struct FlagUserPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case flag
        case currentUser = "user"
        case flaggedUser = "target_user"
    }
    
    /// The payload of a current user who performed flag/unflag action.
    let currentUser: CurrentUserPayload
    /// The payload of a user who was flagged or unflagged.
    let flaggedUser: UserPayload
    
    init(from decoder: Decoder) throws {
        let nestedContainer = try decoder
            .container(keyedBy: CodingKeys.self)
            .nestedContainer(keyedBy: CodingKeys.self, forKey: .flag)
        
        self.init(
            currentUser: try nestedContainer.decode(CurrentUserPayload.self, forKey: .currentUser),
            flaggedUser: try nestedContainer.decode(UserPayload.self, forKey: .flaggedUser)
        )
    }
    
    init(
        currentUser: CurrentUserPayload,
        flaggedUser: UserPayload
    ) {
        self.currentUser = currentUser
        self.flaggedUser = flaggedUser
    }
}
