//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChatChannelSearchController_Mock: ChatChannelSearchController, @unchecked Sendable {
    static func mock(client: ChatClient? = nil) -> ChatChannelSearchController_Mock {
        .init(client: client ?? .mock())
    }

    var channels_mock: [ChatChannel]?
    override var channels: [ChatChannel] {
        channels_mock ?? super.channels
    }

    var state_mock: DataController.State?
    override var state: DataController.State {
        get {
            state_mock ?? super.state
        }
        set {
            state_mock = newValue
        }
    }

    var loadNextChannelsCallCount = 0
    override func loadNextChannels(
        limit: Int? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        loadNextChannelsCallCount += 1
        callback {
            completion?(nil)
        }
    }

    var searchCallCount = 0
    override func search(query: ChannelListQuery, completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        searchCallCount += 1
        callback {
            completion?(nil)
        }
    }

    override func search(text: String, completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        searchCallCount += 1
        callback {
            completion?(nil)
        }
    }

    var clearResultsCallCount = 0
    override func clearResults(completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        clearResultsCallCount += 1
        callback {
            completion?(nil)
        }
    }
}
