//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestTools

class OfflineRequestsRepositoryMock: OfflineRequestsRepository, Spy {
    var recordedFunctions: [String] = []

    override func runQueuedRequests(completion: @escaping () -> Void) {
        record()
        completion()
    }

    override func queueOfflineRequest(endpoint: DataEndpoint) {
        record()
    }
}
