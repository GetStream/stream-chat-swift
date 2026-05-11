//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChannelInput {
    static var unique: Self {
        Self(
            name: .unique,
            imageURL: .unique(),
            team: .unique,
            members: [],
            invites: [],
            filterTags: [],
            extraData: .init()
        )
    }
}
