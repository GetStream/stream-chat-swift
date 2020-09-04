//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension ChannelControllerGeneric {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<Controller.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the channel changes.
    public var channelChangePublisher: AnyPublisher<EntityChange<ChannelModel<ExtraData>>, Never> {
        basePublishers.channelChange.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the list of the messages matching the query changes.
    public var messagesChangesPublisher: AnyPublisher<[ListChange<MessageModel<ExtraData>>], Never> {
        basePublishers.messagesChanges.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time member event received.
    public var memberEventPublisher: AnyPublisher<MemberEvent, Never> {
        basePublishers.memberEvent.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time typing event received.
    public var typingEventPublisher: AnyPublisher<TypingEvent, Never> {
        basePublishers.typingEvent.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: ChannelControllerGeneric
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<Controller.State, Never>
        
        /// A backing subject for `channelChangePublisher`.
        let channelChange: PassthroughSubject<EntityChange<ChannelModel<ExtraData>>, Never> = .init()
        
        /// A backing subject for `messagesChangesPublisher`.
        let messagesChanges: PassthroughSubject<[ListChange<MessageModel<ExtraData>>], Never> = .init()
        
        /// A backing subject for `memberEventPublisher`.
        let memberEvent: PassthroughSubject<MemberEvent, Never> = .init()
        
        /// A backing subject for `typingEventPublisher`.
        let typingEvent: PassthroughSubject<TypingEvent, Never> = .init()
                
        init(controller: ChannelControllerGeneric<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyChannelControllerDelegate(self))
            
            if controller.state == .inactive {
                // Start updating and load the current data
                controller.startUpdating()
            }
        }
    }
}

@available(iOS 13, *)
extension ChannelControllerGeneric.BasePublishers: ChannelControllerDelegateGeneric {
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state.send(state)
    }

    func channelController(
        _ channelController: ChannelControllerGeneric<ExtraData>,
        didUpdateChannel channel: EntityChange<ChannelModel<ExtraData>>
    ) {
        channelChange.send(channel)
    }

    func channelController(
        _ channelController: ChannelControllerGeneric<ExtraData>,
        didUpdateMessages changes: [ListChange<MessageModel<ExtraData>>]
    ) {
        messagesChanges.send(changes)
    }

    func channelController(_ channelController: ChannelControllerGeneric<ExtraData>, didReceiveMemberEvent event: MemberEvent) {
        memberEvent.send(event)
    }

    func channelController(_ channelController: ChannelControllerGeneric<ExtraData>, didReceiveTypingEvent event: TypingEvent) {
        typingEvent.send(event)
    }
}
