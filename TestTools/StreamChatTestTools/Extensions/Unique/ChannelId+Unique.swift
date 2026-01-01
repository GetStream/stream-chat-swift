//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

extension ChannelId {
    public static var unique: ChannelId {
        ChannelId(
            type: .custom(String.unique.lowercased().replacingOccurrences(of: "-", with: "_")),
            id: .unique
        )
    }
}
