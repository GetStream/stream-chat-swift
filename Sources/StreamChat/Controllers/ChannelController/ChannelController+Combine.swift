//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension _ChatChannelController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the channel changes.
    public var channelChangePublisher: AnyPublisher<EntityChange<_ChatChannel<ExtraData>>, Never> {
        basePublishers.channelChange.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the list of the messages matching the query changes.
    public var messagesChangesPublisher: AnyPublisher<[ListChange<_ChatMessage<ExtraData>>], Never> {
        basePublishers.messagesChanges.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time member event received.
    public var memberEventPublisher: AnyPublisher<MemberEvent, Never> {
        basePublishers.memberEvent.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time typing users change.
    public var typingUsersPublisher: AnyPublisher<Set<_ChatUser<ExtraData.User>>, Never> {
        basePublishers.typingUsers.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: _ChatChannelController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `channelChangePublisher`.
        let channelChange: PassthroughSubject<EntityChange<_ChatChannel<ExtraData>>, Never> = .init()
        
        /// A backing subject for `messagesChangesPublisher`.
        let messagesChanges: PassthroughSubject<[ListChange<_ChatMessage<ExtraData>>], Never> = .init()
        
        /// A backing subject for `memberEventPublisher`.
        let memberEvent: PassthroughSubject<MemberEvent, Never> = .init()
        
        /// A backing subject for `typingUsersPublisher`.
        let typingUsers: PassthroughSubject<Set<_ChatUser<ExtraData.User>>, Never> = .init()
                
        init(controller: _ChatChannelController<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyChannelControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatChannelController.BasePublishers: _ChatChannelControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        channelChange.send(channel)
    }

    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messagesChanges.send(changes)
    }

    func channelController(_ channelController: _ChatChannelController<ExtraData>, didReceiveMemberEvent event: MemberEvent) {
        memberEvent.send(event)
    }
    
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingUsers typingUsers: Set<_ChatUser<ExtraData.User>>
    ) {
        self.typingUsers.send(typingUsers)
    }
}
