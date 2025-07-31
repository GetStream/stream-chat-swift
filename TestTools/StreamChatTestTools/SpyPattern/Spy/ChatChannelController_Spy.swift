//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class ChatChannelController_Spy: ChatChannelController, Spy, @unchecked Sendable {
    var watchActiveChannelError: Error?
    let spyState = SpyState()

    init(client: ChatClient_Mock) {
        super.init(channelQuery: .init(cid: .unique), channelListQuery: nil, client: client)
    }

    override func recoverWatchedChannel(recovery: Bool, completion: @escaping @MainActor @Sendable(Error?) -> Void) {
        record()
        callback {
            completion(self.watchActiveChannelError)
        }
    }
}

final class ChannelControllerSpy: ChatChannelController, @unchecked Sendable {
    @Atomic var synchronize_called = false

    var channel_simulated: ChatChannel?
    override var channel: ChatChannel? {
        channel_simulated
    }

    var messages_simulated: [ChatMessage]?
    override var messages: LazyCachedMapCollection<ChatMessage> {
        messages_simulated.map { $0.lazyCachedMap { $0 } } ?? super.messages
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }

    init(channelQuery: ChannelQuery = .init(channelPayload: .unique)) {
        super.init(
            channelQuery: channelQuery,
            channelListQuery: nil,
            client: .mock
        )
    }

    override func synchronize(_ completion: (@MainActor @Sendable(Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}
