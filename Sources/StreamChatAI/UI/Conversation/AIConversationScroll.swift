//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Where the list scrolls when its last turn changes. A turn added after the previous last
// one was just sent, so it goes to the top. Otherwise the conversation loaded or was
// replaced, and it opens at its end.
enum AIConversationScroll: Equatable {
    case toTop(AnyHashable)
    case toEnd
    case none

    init(previousLastTurnID: AnyHashable?, turnIDs: [AnyHashable]) {
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
