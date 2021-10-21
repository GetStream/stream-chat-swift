//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatChannelController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `ChannelListController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatChannelController
        
        /// The channel matching the ChannelId.
        @Published public private(set) var channel: ChatChannel?
        
        /// The messages related to the channel.
        @Published public private(set) var messages: LazyCachedMapCollection<ChatMessage> = []
        
        /// The current state of the Controller.
        @Published public private(set) var state: DataController.State
        
        /// The typing users related to the channel.
        @Published public private(set) var typingUsers: Set<ChatUser> = []
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatChannelController) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.add(additionalDelegate: self)
            
            channel = controller.channel
            messages = controller.messages
            typingUsers = controller.channel?.currentlyTypingUsers ?? []
        }
    }
}

@available(iOS 13, *)
extension ChatChannelController.ObservableObject: ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        self.channel = channelController.channel
    }
   
    public func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        messages = channelController.messages
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
    
    public func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        self.typingUsers = typingUsers
    }
}
