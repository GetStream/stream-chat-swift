//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChannelListControllerGeneric {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `ChannelListController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChannelListControllerGeneric
        
        /// The channels matching the query.
        @Published public private(set) var channels: [ChannelModel<ExtraData>] = []
        
        /// The current state of the Controller.
        @Published public private(set) var state: Controller.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChannelListControllerGeneric<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChannelListControllerDelegate(self))
            
            if controller.state == .inactive {
                // Start updating and load the current data
                controller.startUpdating()
            }
            
            channels = controller.channels
        }
    }
}

@available(iOS 13, *)
extension ChannelListControllerGeneric.ObservableObject: ChannelListControllerDelegateGeneric {
    public func controller(
        _ controller: ChannelListControllerGeneric<ExtraData>,
        didChangeChannels changes: [ListChange<ChannelModel<ExtraData>>]
    ) {
        // We don't care about detailed changes. We just need to update the `channels` property and keep SwiftUI
        // deal with the rest.
        channels = controller.channels
    }
    
    public func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
    }
}
