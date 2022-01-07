//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension ChatChannelController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the channel changes.
    public var channelChangePublisher: AnyPublisher<EntityChange<ChatChannel>, Never> {
        basePublishers.channelChange.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the list of the messages matching the query changes.
    public var messagesChangesPublisher: AnyPublisher<[ListChange<ChatMessage>], Never> {
        basePublishers.messagesChanges.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time member event received.
    public var memberEventPublisher: AnyPublisher<MemberEvent, Never> {
        basePublishers.memberEvent.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time typing users change.
    public var typingUsersPublisher: AnyPublisher<Set<ChatUser>, Never> {
        basePublishers.typingUsers.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: ChatChannelController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `channelChangePublisher`.
        let channelChange: PassthroughSubject<EntityChange<ChatChannel>, Never> = .init()
        
        /// A backing subject for `messagesChangesPublisher`.
        let messagesChanges: PassthroughSubject<[ListChange<ChatMessage>], Never> = .init()
        
        /// A backing subject for `memberEventPublisher`.
        let memberEvent: PassthroughSubject<MemberEvent, Never> = .init()
        
        /// A backing subject for `typingUsersPublisher`.
        let typingUsers: PassthroughSubject<Set<ChatUser>, Never> = .init()
                
        init(controller: ChatChannelController) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

@available(iOS 13, *)
extension ChatChannelController.BasePublishers: ChatChannelControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        channelChange.send(channel)
    }

    func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        messagesChanges.send(changes)
    }

    func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent event: MemberEvent) {
        memberEvent.send(event)
    }
    
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        self.typingUsers.send(typingUsers)
    }
}
