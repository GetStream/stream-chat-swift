//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChatMessageSearchController_Mock: ChatMessageSearchController {
    static func mock(client: ChatClient? = nil) -> ChatMessageSearchController_Mock {
        .init(client: client ?? .mock())
    }

    var messages_mock: LazyCachedMapCollection<ChatMessage>?
    override var messages: LazyCachedMapCollection<ChatMessage> {
        messages_mock ?? super.messages
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

    var loadNextMessagesCallCount = 0
    override func loadNextMessages(limit: Int = 25, completion: ((Error?) -> Void)? = nil) {
        loadNextMessagesCallCount += 1
        completion?(nil)
    }

    var searchCallCount = 0
    override func search(query: MessageSearchQuery, completion: ((Error?) -> Void)? = nil) {
        searchCallCount += 1
        completion?(nil)
    }

    override func search(text: String, completion: ((Error?) -> Void)? = nil) {
        searchCallCount += 1
    }
}
