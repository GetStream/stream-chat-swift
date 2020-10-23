//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct HideChannelRequest: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case clearHistory = "clear_history"
    }

    let userId: String
    let clearHistory: Bool
}
