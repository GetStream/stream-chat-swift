//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat

extension ChannelId {
    static var unique: ChannelId {
        ChannelId(
            type: .custom(String.unique.lowercased().replacingOccurrences(of: "-", with: "_")),
            id: .unique
        )
    }
}
