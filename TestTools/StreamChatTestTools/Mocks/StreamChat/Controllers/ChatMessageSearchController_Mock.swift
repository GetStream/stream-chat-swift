//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatMessageSearchController_Mock: ChatMessageSearchController {
    public static func mock(client: ChatClient? = nil) -> ChatMessageSearchController_Mock {
        .init(client: client ?? .mock())
    }

    public var messages_mock: LazyCachedMapCollection<ChatMessage>?
    override public var messages: LazyCachedMapCollection<ChatMessage> {
        messages_mock ?? super.messages
    }

    public var state_mock: DataController.State?
    public override var state: DataController.State {
        get {
            state_mock ?? super.state
        }
        set {
            state_mock = newValue
        }
    }

    var loadNextMessagesCallCount = 0
    override public func loadNextMessages(limit: Int = 25, completion: ((Error?) -> Void)? = nil) {
        loadNextMessagesCallCount += 1
        completion?(nil)
    }

    var searchCallCount = 0
    override public func search(query: MessageSearchQuery, completion: ((Error?) -> Void)? = nil) {
        searchCallCount += 1
        completion?(nil)
    }

    public override func search(text: String, completion: ((Error?) -> Void)? = nil) {
        searchCallCount += 1
    }
}
