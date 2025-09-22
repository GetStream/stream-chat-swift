//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class LivestreamChannelController_Spy: LivestreamChannelController, Spy, @unchecked Sendable {
    var startWatchingError: Error?
    let spyState = SpyState()

    init(client: ChatClient_Mock) {
        super.init(channelQuery: .init(cid: .unique), client: client)
    }

    override func startWatching(isInRecoveryMode: Bool, completion: (@MainActor(Error?) -> Void)? = nil) {
        record()
        StreamConcurrency.onMain {
            completion?(startWatchingError)
        }
    }
}
