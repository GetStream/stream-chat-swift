//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatMessageController_Mock<ExtraData: ExtraDataTypes>: _ChatMessageController<ExtraData> {
    /// Creates a new mock instance of `ChatMessageController`.
    public static func mock() -> ChatMessageController_Mock<ExtraData> {
        .init(client: .mock(), cid: try! .init(cid: "mock:channel"), messageId: "MockMessage")
    }
    
    public private(set) var message_mock: _ChatMessage?
    override public var message: _ChatMessage? {
        message_mock ?? super.message
    }

    public private(set) var replies_mock: [_ChatMessage]?
    override public var replies: LazyCachedMapCollection<ChatMessage> {
        replies_mock.map { $0.lazyCachedMap { $0 } } ?? super.replies
    }

    public private(set) var state_mock: State?
    override public var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }
}

public extension ChatMessageController_Mock {
    /// Simulates the initial conditions. Setting these values doesn't trigger any observer callback.
    func simulateInitial(message: _ChatMessage, replies: [_ChatMessage], state: DataController.State) {
        message_mock = message
        replies_mock = replies
        state_mock = state
        // Initial simulation should also have a user pre-created
        try? client.databaseContainer.createCurrentUser()
    }
    
    /// Simulates a change of the `message` value. Observers are notified with the provided `change` value.
    func simulate(message: _ChatMessage?, change: EntityChange<ChatMessage>) {
        message_mock = message
        delegateCallback {
            $0.messageController(self, didChangeMessage: change)
        }
    }
    
    /// Simulates changes in the `replies` array. Observers are notified with the provided `changes` value.
    func simulate(replies: [_ChatMessage], changes: [ListChange<ChatMessage>]) {
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
