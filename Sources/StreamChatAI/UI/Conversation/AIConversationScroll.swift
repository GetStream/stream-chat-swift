//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Where the list scrolls when its last turn changes. A turn added after the previous last
// one was just sent, so it goes to the top. Otherwise the conversation loaded or was
// replaced, and it opens at its end.
enum AIConversationScroll<ID: Hashable>: Equatable {
    case toTop(ID)
    case toEnd
    case none

    init(previousLastTurnID: ID?, turnIDs: [ID]) {
        guard let lastTurnID = turnIDs.last, lastTurnID != previousLastTurnID else {
            self = .none
            return
        }
        if let previousLastTurnID, turnIDs.contains(previousLastTurnID) {
            self = .toTop(lastTurnID)
        } else {
            self = .toEnd
        }
    }
}
