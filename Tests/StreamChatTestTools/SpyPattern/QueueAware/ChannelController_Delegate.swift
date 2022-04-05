//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// A concrete `ChannelControllerDelegate` implementation allowing capturing the delegate calls
final class ChannelController_Delegate: QueueAwareDelegate, ChatChannelControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var willStartFetchingRemoteDataCalledCounter = 0
    @Atomic var didStopFetchingRemoteDataCalledCounter = 0
    @Atomic var didUpdateChannel_channel: EntityChange<ChatChannel>?
    @Atomic var didUpdateMessages_messages: [ListChange<ChatMessage>]?
    @Atomic var didReceiveMemberEvent_event: MemberEvent?
    @Atomic var didChangeTypingUsers_typingUsers: Set<ChatUser>?

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        willStartFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }

    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        didStopFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }

    func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
        didUpdateMessages_messages = changes
        validateQueue()
    }

    func channelController(_ channelController: ChatChannelController, didUpdateChannel channel: EntityChange<ChatChannel>) {
        didUpdateChannel_channel = channel
        validateQueue()
    }

    func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent event: MemberEvent) {
        didReceiveMemberEvent_event = event
        validateQueue()
    }

    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        didChangeTypingUsers_typingUsers = typingUsers
        validateQueue()
    }
}
