//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension CleanUpTypingEvent: @retroactive Equatable {
    public static func == (lhs: CleanUpTypingEvent, rhs: CleanUpTypingEvent) -> Bool {
        lhs.cid == rhs.cid && lhs.userId == rhs.userId
    }
}
