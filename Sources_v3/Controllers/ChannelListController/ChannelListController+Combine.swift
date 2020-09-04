//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension ChannelListControllerGeneric {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<Controller.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the list of the channels matching the query changes.
    public var channelsChangesPublisher: AnyPublisher<[ListChange<ChannelModel<ExtraData>>], Never> {
        basePublishers.channelsChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: ChannelListControllerGeneric
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<Controller.State, Never>
        
        /// A backing subject for `channelsChangesPublisher`.
        let channelsChanges: PassthroughSubject<[ListChange<ChannelModel<ExtraData>>], Never> = .init()
                
        init(controller: ChannelListControllerGeneric<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyChannelListControllerDelegate(self))
            
            if controller.state == .inactive {
                // Start updating and load the current data
                controller.startUpdating()
            }
        }
    }
}

@available(iOS 13, *)
extension ChannelListControllerGeneric.BasePublishers: ChannelListControllerDelegateGeneric {
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state.send(state)
    }
    
    func controller(
        _ controller: ChannelListControllerGeneric<ExtraData>,
        didChangeChannels changes: [ListChange<ChannelModel<ExtraData>>]
    ) {
        channelsChanges.send(changes)
    }
}
