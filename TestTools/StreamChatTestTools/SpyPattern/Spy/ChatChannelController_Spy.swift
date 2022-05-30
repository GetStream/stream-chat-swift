//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class ChatChannelController_Spy: ChatChannelController, Spy {
    var watchActiveChannelError: Error?
    var recordedFunctions: [String] = []

    init(client: ChatClient_Mock) {
        super.init(channelQuery: .init(cid: .unique), channelListQuery: nil, client: client)
    }

    override func recoverWatchedChannel(completion: @escaping (Error?) -> Void) {
        record()
        completion(watchActiveChannelError)
    }
}

final class ChannelControllerSpy: ChatChannelController {
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

    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}
