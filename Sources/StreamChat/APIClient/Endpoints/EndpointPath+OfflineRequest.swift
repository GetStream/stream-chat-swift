//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        switch self {
        case .sendMessage,
             .updateMessage,
             .updateMessagePartial,
             .deleteMessage,
             .sendReaction,
             .deleteReaction,
             .createDraft,
             .deleteDraft:
            return true
        default:
            return false
        }
    }
}

extension Endpoint {
    var shouldBeQueuedOffline: Bool {
        path.shouldBeQueuedOffline
    }
}
