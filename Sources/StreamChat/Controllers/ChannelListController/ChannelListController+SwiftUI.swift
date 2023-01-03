//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatChannelListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }

    /// A wrapper object for `ChannelListController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatChannelListController

        /// The channels matching the query.
        @Published public private(set) var channels: LazyCachedMapCollection<ChatChannel> = []

        /// The current state of the Controller.
        @Published public private(set) var state: DataController.State

        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatChannelListController) {
            self.controller = controller
            state = controller.state

            controller.multicastDelegate.add(additionalDelegate: self)
            channels = controller.channels
        }
    }
}

@available(iOS 13, *)
extension ChatChannelListController.ObservableObject: ChatChannelListControllerDelegate {
    public func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        // We don't care about detailed changes. We just need to update the `channels` property and keep SwiftUI
        // deal with the rest.
        channels = controller.channels
    }

    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }

    public func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        // Use the mainDelegate if exists, or true by default
        controller.multicastDelegate.mainDelegate?.controller(controller, shouldListUpdatedChannel: channel) ?? true
    }

    public func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        // Use the mainDelegate if exists, or true by default
        controller.multicastDelegate.mainDelegate?.controller(controller, shouldAddNewChannelToList: channel) ?? true
    }
}
