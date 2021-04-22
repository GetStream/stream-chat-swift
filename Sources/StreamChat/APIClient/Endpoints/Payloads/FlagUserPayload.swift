//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming JSON from `moderation/(un)flag` user endpoint.
struct FlagUserPayload<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case flag
        case currentUser = "user"
        case flaggedUser = "target_user"
    }
    
    /// The payload of a current user who performed flag/unflag action.
    let currentUser: CurrentUserPayload<ExtraData>
    /// The payload of a user who was flagged or unflagged.
    let flaggedUser: UserPayload<ExtraData.User>
    
    init(from decoder: Decoder) throws {
        let nestedContainer = try decoder
            .container(keyedBy: CodingKeys.self)
            .nestedContainer(keyedBy: CodingKeys.self, forKey: .flag)
        
        self.init(
            currentUser: try nestedContainer.decode(CurrentUserPayload<ExtraData>.self, forKey: .currentUser),
            flaggedUser: try nestedContainer.decode(UserPayload<ExtraData.User>.self, forKey: .flaggedUser)
        )
    }
    
    init(
        currentUser: CurrentUserPayload<ExtraData>,
        flaggedUser: UserPayload<ExtraData.User>
    ) {
        self.currentUser = currentUser
        self.flaggedUser = flaggedUser
    }
}
