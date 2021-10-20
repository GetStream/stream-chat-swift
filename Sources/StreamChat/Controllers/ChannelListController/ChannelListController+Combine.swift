//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension ChatChannelListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the list of the channels matching the query changes.
    public var channelsChangesPublisher: AnyPublisher<[ListChange<ChatChannel>], Never> {
        basePublishers.channelsChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: ChatChannelListController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `channelsChangesPublisher`.
        let channelsChanges: PassthroughSubject<[ListChange<ChatChannel>], Never> = .init()
                
        init(controller: ChatChannelListController) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

@available(iOS 13, *)
extension ChatChannelListController.BasePublishers: ChatChannelListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        channelsChanges.send(changes)
    }
    
    func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        // Use the mainDelegate if exists, or true by default
        controller.multicastDelegate.mainDelegate?.controller(controller, shouldListUpdatedChannel: channel) ?? true
    }
    
    func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        // Use the mainDelegate if exists, or true by default
        controller.multicastDelegate.mainDelegate?.controller(controller, shouldAddNewChannelToList: channel) ?? true
    }
}
