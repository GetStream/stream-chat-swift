//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChatChannelController` uses this protocol to communicate changes to its delegate.
public protocol ChatChannelControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `Channel` entity.
    func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    )

    /// The controller observed changes in the `Messages` of the observed channel.
    func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    )

    /// The controller received a `MemberEvent` related to the channel it observes.
    func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent: MemberEvent)

    /// The controller received a change related to users typing in the channel it observes.
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    )
}

public extension ChatChannelControllerDelegate {
    func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {}

    func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {}

    func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent: MemberEvent) {}

    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers: Set<ChatUser>
    ) {}
}
