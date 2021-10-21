//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatChannelWatcherListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `_ChatChannelWatcherListController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatChannelWatcherListController
        
        /// The channel members.
        @Published public private(set) var watchers: LazyCachedMapCollection<ChatUser> = []
        
        /// The current state of the controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatChannelWatcherListController) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.add(additionalDelegate: self)
            
            watchers = controller.watchers
        }
    }
}

@available(iOS 13, *)
extension ChatChannelWatcherListController.ObservableObject: ChatChannelWatcherListControllerDelegate {
    public func channelWatcherListController(
        _ controller: ChatChannelWatcherListController,
        didChangeWatchers changes: [ListChange<ChatUser>]
    ) {
        watchers = controller.watchers
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
