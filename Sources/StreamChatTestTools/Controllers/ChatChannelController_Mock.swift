//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatChannelController_Mock<ExtraData: ExtraDataTypes>: _ChatChannelController<ExtraData> {
    /// Creates a new mock instance of `ChatChannelController`.
    public static func mock() -> ChatChannelController_Mock<ExtraData> {
        .init(channelQuery: .init(cid: try! .init(cid: "mock:channel")), client: .mock())
    }
    
    public var channel_mock: _ChatChannel<ExtraData>?
    override public var channel: _ChatChannel<ExtraData>? {
        channel_mock ?? super.channel
    }
    
    public private(set) var messages_mock: [_ChatMessage<ExtraData>]?
    override public var messages: LazyCachedMapCollection<_ChatMessage<ExtraData>> {
        messages_mock.map { $0.lazyCachedMap { $0 } } ?? super.messages
    }

    public private(set) var state_mock: State?
    override public var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    public private(set) var synchronize_completion: ((Error?) -> Void)?
    override public func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_completion = completion
    }
}

public extension ChatChannelController_Mock {
    /// Simulates the initial conditions. Setting these values doesn't trigger any observer callback.
    func simulateInitial(channel: _ChatChannel<ExtraData>, messages: [_ChatMessage<ExtraData>], state: DataController.State) {
        channel_mock = channel
        messages_mock = messages
        state_mock = state
    }
    
    /// Simulates a change of the `channel` value. Observers are notified with the provided `change` value. If `typingUsers`
    /// value is explicitly provided, `didChangeTypingUsers` is called, too.
    func simulate(
        channel: _ChatChannel<ExtraData>?,
        change: EntityChange<_ChatChannel<ExtraData>>,
        typingUsers: Set<_ChatChannelMember<ExtraData.User>>?
    ) {
        channel_mock = channel
        delegateCallback {
            $0.channelController(self, didUpdateChannel: change)
            if let typingUsers = typingUsers {
                $0.channelController(self, didChangeTypingUsers: typingUsers)
            }
        }
    }
    
    /// Simulates changes in the `messages` array. Observers are notified with the provided `changes` value.
    func simulate(messages: [_ChatMessage<ExtraData>], changes: [ListChange<_ChatMessage<ExtraData>>]) {
        messages_mock = messages
        delegateCallback {
            $0.channelController(self, didUpdateMessages: changes)
        }
    }
    
    /// Simulates a received member event.
    func simulate(memberEvent: MemberEvent) {
        delegateCallback {
            $0.channelController(self, didReceiveMemberEvent: memberEvent)
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
