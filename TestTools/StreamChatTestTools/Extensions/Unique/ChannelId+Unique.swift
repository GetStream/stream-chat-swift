//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

extension ChannelId {
    static public var unique: ChannelId {
        ChannelId(
            type: .custom(String.unique.lowercased().replacingOccurrences(of: "-", with: "_")),
            id: .unique
        )
    }
}
