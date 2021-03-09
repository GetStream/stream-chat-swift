//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension _ChatChannelWatcherListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `_ChatChannelWatcherListController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: _ChatChannelWatcherListController
        
        /// The channel members.
        @Published public private(set) var watchers: LazyCachedMapCollection<_ChatUser<ExtraData.User>> = []
        
        /// The current state of the controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: _ChatChannelWatcherListController<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatChannelWatcherListControllerDelegate(self))
            
            watchers = controller.watchers
        }
    }
}

@available(iOS 13, *)
extension _ChatChannelWatcherListController.ObservableObject: _ChatChannelWatcherListControllerDelegate {
    public func channelWatcherListController(
        _ controller: _ChatChannelWatcherListController<ExtraData>,
        didChangeWatchers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        watchers = controller.watchers
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
