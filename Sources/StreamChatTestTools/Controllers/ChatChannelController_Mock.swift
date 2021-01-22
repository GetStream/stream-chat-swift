//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatChannelController_Mock<ExtraData: ExtraDataTypes>: _ChatChannelController<ExtraData> {
    /// Creates a new mock instance of `ChatChannelController`.
    public static func mock() -> ChatChannelController_Mock<ExtraData> {
        .init(channelQuery: .init(cid: try! .init(cid: "Mock:Channel")), client: .mock())
    }
    
    public private(set) var channel_mock: _ChatChannel<ExtraData>?
    override public var channel: _ChatChannel<ExtraData>? {
        channel_mock ?? super.channel
    }
    
    public private(set) var messages_mock: [_ChatMessage<ExtraData>]?
    override public var messages: [_ChatMessage<ExtraData>] {
        messages_mock ?? super.messages
    }

    public private(set) var state_mock: State?
    override public var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }
}

public extension ChatChannelController_Mock {
    /// Simulates the initial conditions. Setting these values doesn't trigger any observer callback.
    func simulateInitial(channel: _ChatChannel<ExtraData>, messages: [_ChatMessage<ExtraData>], state: DataController.State) {
        channel_mock = channel
        messages_mock = messages
        state_mock = state
    }
    
    /// Simulates a change of the `channel` value. Observers are notified with the provided `change` value. If `typingMembers`
    /// value is explicitly provided, `didChangeTypingMembers` is called, too.
    func simulate(
        channel: _ChatChannel<ExtraData>?,
        change: EntityChange<_ChatChannel<ExtraData>>,
        typingMembers: Set<_ChatChannelMember<ExtraData.User>>?
    ) {
        channel_mock = channel
        delegateCallback {
            $0.channelController(self, didUpdateChannel: change)
            if let typingMembers = typingMembers {
                $0.channelController(self, didChangeTypingMembers: typingMembers)
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
