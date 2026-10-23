//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension FullUserResponse {
    var id: String { user.id }
}

extension ThreadStateResponse {
    var parentMessageId: String { thread.parentMessageId }
}
