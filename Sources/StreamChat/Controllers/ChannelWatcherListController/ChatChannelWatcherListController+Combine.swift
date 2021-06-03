//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension _ChatChannelWatcherListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the channel members change.
    public var watchersChangesPublisher: AnyPublisher<[ListChange<_ChatUser<ExtraData.User>>], Never> {
        basePublishers.watchersChanges.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: _ChatChannelWatcherListController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `membersChangesPublisher`.
        let watchersChanges: PassthroughSubject<[ListChange<_ChatUser<ExtraData.User>>], Never> = .init()
        
        init(controller: _ChatChannelWatcherListController<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatChannelWatcherListControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatChannelWatcherListController.BasePublishers: _ChatChannelWatcherListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func channelWatcherListController(
        _ controller: _ChatChannelWatcherListController<ExtraData>,
        didChangeWatchers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        watchersChanges.send(changes)
    }
}
