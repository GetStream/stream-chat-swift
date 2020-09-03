//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChannelControllerGeneric {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `ChannelListController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChannelControllerGeneric
        
        /// The channel matching the ChannelId.
        @Published public private(set) var channel: ChannelModel<ExtraData>?
        
        /// The messages related to the channel.
        @Published public private(set) var messages: [MessageModel<ExtraData>] = []
        
        /// The current state of the Controller.
        @Published public private(set) var state: Controller.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChannelControllerGeneric<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChannelControllerDelegate(self))
            
            if controller.state == .inactive {
                // Start updating and load the current data
                controller.startUpdating()
            }
            
            channel = controller.channel
            messages = controller.messages
        }
    }
}

@available(iOS 13, *)
extension ChannelControllerGeneric.ObservableObject: ChannelControllerDelegateGeneric {
    public func channelController(
        _ channelController: ChannelControllerGeneric<ExtraData>,
        didUpdateChannel channel: EntityChange<ChannelModel<ExtraData>>
    ) {
        self.channel = channelController.channel
    }
   
    public func channelController(
        _ channelController: ChannelControllerGeneric<ExtraData>,
        didUpdateMessages changes: [ListChange<MessageModel<ExtraData>>]
    ) {
        messages = channelController.messages
    }
    
    public func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
    }
}
