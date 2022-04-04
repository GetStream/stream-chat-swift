//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ChannelListControllerDelegate` implementation allowing capturing the delegate calls
final class ChannelListController_Delegate: QueueAwareDelegate, ChatChannelListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var willChangeChannels_called = false
    @Atomic var didChangeChannels_changes: [ListChange<ChatChannel>]?

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func controllerWillChangeChannels(_ controller: ChatChannelListController) {
        willChangeChannels_called = true
        validateQueue()
    }

    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        didChangeChannels_changes = changes
        validateQueue()
    }

    func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        validateQueue()
        return true
    }

    func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        validateQueue()
        return true
    }
}

// A concrete `LinkDelegate` implementation allowing capturing the delegate calls
final class TestLinkDelegate: ChatChannelListControllerDelegate {
    let shouldListNewChannel: (ChatChannel) -> Bool
    let shouldListUpdatedChannel: (ChatChannel) -> Bool
    init(
        shouldListNewChannel: @escaping (ChatChannel) -> Bool,
        shouldListUpdatedChannel: @escaping (ChatChannel) -> Bool
    ) {
        self.shouldListNewChannel = shouldListNewChannel
        self.shouldListUpdatedChannel = shouldListUpdatedChannel
    }

    func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        shouldListNewChannel(channel)
    }

    func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        shouldListUpdatedChannel(channel)
    }
}
