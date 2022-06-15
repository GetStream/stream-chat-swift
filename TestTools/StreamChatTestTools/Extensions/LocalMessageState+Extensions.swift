//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension LocalMessageState {
    static let failedStates: [Self] = [
        .sendingFailed,
        .bounced,
        .syncingFailed,
        .deletingFailed
    ]
    
    static let pendingStates: [Self] = [
        .pendingSend,
        .sending,
        .pendingSync,
        .syncing,
        .deleting
    ]
}
