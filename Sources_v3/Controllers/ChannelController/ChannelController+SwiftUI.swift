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
        @Published public private(set) var channel: _ChatChannel<ExtraData>?
        
        /// The messages related to the channel.
        @Published public private(set) var messages: [_ChatMessage<ExtraData>] = []
        
        /// The current state of the Controller.
        @Published public private(set) var state: DataController.State
        
        /// The typing members related to the channel.
        @Published public private(set) var typingMembers: Set<MemberModel<ExtraData.User>> = []
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChannelControllerGeneric<ExtraData>) {
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
extension ChannelControllerGeneric.ObservableObject: ChannelControllerDelegateGeneric {
    public func channelController(
        _ channelController: ChannelControllerGeneric<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        self.channel = channelController.channel
    }
   
    public func channelController(
        _ channelController: ChannelControllerGeneric<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messages = channelController.messages
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
    
    public func channelController(
        _ channelController: ChannelControllerGeneric<ExtraData>,
        didChangeTypingMembers typingMembers: Set<MemberModel<ExtraData.User>>
    ) {
        self.typingMembers = typingMembers
    }
}
