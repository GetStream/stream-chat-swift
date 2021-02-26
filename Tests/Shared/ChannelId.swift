//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

extension ChannelId {
    static var unique: ChannelId { ChannelId(type: .custom(.unique), id: .unique) }
}
