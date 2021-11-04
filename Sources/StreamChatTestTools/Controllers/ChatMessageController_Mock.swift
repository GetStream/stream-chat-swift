//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatMessageController_Mock: ChatMessageController {
    /// Creates a new mock instance of `ChatMessageController`.
    public static func mock(currentUserId: UserId = "ID") -> ChatMessageController_Mock {
        let chatClient = ChatClient.mock()
        chatClient.currentUserId = currentUserId
        return .init(client: chatClient, cid: try! .init(cid: "mock:channel"), messageId: "MockMessage")
    }
    
    public var message_mock: ChatMessage?
    override public var message: ChatMessage? {
        message_mock ?? super.message
    }

    public var replies_mock: [ChatMessage]?
    override public var replies: LazyCachedMapCollection<ChatMessage> {
        replies_mock.map { $0.lazyCachedMap { $0 } } ?? super.replies
    }

    public var state_mock: State?
    override public var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    public var startObserversIfNeeded_mock: (() -> Void)?
    override public func startObserversIfNeeded() {
        if let mock = startObserversIfNeeded_mock {
            mock()
            return
        }

        super.startObserversIfNeeded()
    }

    var synchronize_callCount = 0
    override public func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_callCount += 1
    }
}

public extension ChatMessageController_Mock {
    /// Simulates the initial conditions. Setting these values doesn't trigger any observer callback.
    func simulateInitial(message: ChatMessage, replies: [ChatMessage], state: DataController.State) {
        message_mock = message
        replies_mock = replies
        state_mock = state
        // Initial simulation should also have a user pre-created
        try? client.databaseContainer.createCurrentUser()
    }
    
    /// Simulates a change of the `message` value. Observers are notified with the provided `change` value.
    func simulate(message: ChatMessage?, change: EntityChange<ChatMessage>) {
        message_mock = message
        delegateCallback {
            $0.messageController(self, didChangeMessage: change)
        }
    }
    
    /// Simulates changes in the `replies` array. Observers are notified with the provided `changes` value.
    func simulate(replies: [ChatMessage], changes: [ListChange<ChatMessage>]) {
        replies_mock = replies
        delegateCallback {
            $0.messageController(self, didChangeReplies: changes)
        }
    }
    
    /// Simulates changes of `state`. Observers are notified with the new value.
    func simulate(state: DataController.State) {
        state_mock = state
        delegateCallback {
            $0.controller(self, didChangeState: state)
        }
    }
}
