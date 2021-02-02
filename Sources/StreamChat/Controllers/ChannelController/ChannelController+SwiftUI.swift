//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension _ChatChannelController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `ChannelListController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: _ChatChannelController
        
        /// The channel matching the ChannelId.
        @Published public private(set) var channel: _ChatChannel<ExtraData>?
        
        /// The messages related to the channel.
        @Published public private(set) var messages: LazyCachedMapCollection<_ChatMessage<ExtraData>> = []
        
        /// The current state of the Controller.
        @Published public private(set) var state: DataController.State
        
        /// The typing members related to the channel.
        @Published public private(set) var typingMembers: Set<_ChatChannelMember<ExtraData.User>> = []
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: _ChatChannelController<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChannelControllerDelegate(self))
            
            channel = controller.channel
            messages = controller.messages
            typingMembers = controller.channel?.currentlyTypingMembers ?? []
        }
    }
}

@available(iOS 13, *)
extension _ChatChannelController.ObservableObject: _ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        self.channel = channelController.channel
    }
   
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messages = channelController.messages
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
    
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers typingMembers: Set<_ChatChannelMember<ExtraData.User>>
    ) {
        self.typingMembers = typingMembers
    }
}
