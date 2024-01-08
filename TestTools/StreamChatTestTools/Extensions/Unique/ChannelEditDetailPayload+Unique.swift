//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChannelEditDetailPayload {
    static var unique: Self {
        Self(
            cid: .unique,
            name: .unique,
            imageURL: .unique(),
            team: .unique,
            members: [],
            invites: [],
            extraData: .init()
        )
    }
}
