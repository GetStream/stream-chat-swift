//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChannelQuery {
    static var unique: Self {
        let cid = ChannelId.unique
        return Self(id: cid.id, type: cid.type, channelPayload: .unique)
    }
}
