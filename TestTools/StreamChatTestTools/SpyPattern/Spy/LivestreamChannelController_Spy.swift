//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class LivestreamChannelController_Spy: LivestreamChannelController, Spy {
    var startWatchingError: Error?
    let spyState = SpyState()

    init(client: ChatClient_Mock) {
        super.init(channelQuery: .init(cid: .unique), client: client)
    }

    override func startWatching(isInRecoveryMode: Bool, completion: ((Error?) -> Void)? = nil) {
        record()
        completion?(startWatchingError)
    }
}
