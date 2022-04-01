//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension CleanUpTypingEvent: Equatable {
    public static func == (lhs: CleanUpTypingEvent, rhs: CleanUpTypingEvent) -> Bool {
        lhs.cid == rhs.cid && lhs.userId == rhs.userId
    }
}
