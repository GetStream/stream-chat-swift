//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension CurrentUserControllerGeneric {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<Controller.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the current user changes.
    public var currentUserChangePublisher: AnyPublisher<EntityChange<CurrentUserModel<ExtraData.User>>, Never> {
        basePublishers.currentUserChange.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the unread count changes..
    public var unreadCountPublisher: AnyPublisher<UnreadCount, Never> {
        basePublishers.unreadCount.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the connection status changes.
    public var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        basePublishers.connectionStatus.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: CurrentUserControllerGeneric
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<Controller.State, Never>
        
        /// A backing subject for `currentUserChangePublisher`.
        let currentUserChange: PassthroughSubject<EntityChange<CurrentUserModel<ExtraData.User>>, Never> = .init()
        
        /// A backing subject for `unreadCountPublisher`.
        let unreadCount: CurrentValueSubject<UnreadCount, Never>
        
        /// A backing subject for `connectionStatusPublisher`.
        let connectionStatus: CurrentValueSubject<ConnectionStatus, Never>
                
        init(controller: CurrentUserControllerGeneric<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            unreadCount = .init(.noUnread)
            connectionStatus = .init(controller.connectionStatus)
            
            controller.multicastDelegate.additionalDelegates.append(AnyCurrentUserControllerDelegate(self))
            
            if controller.state == .inactive {
                // Start updating and load the current data
                controller.startUpdating()
            }
        }
    }
}

@available(iOS 13, *)
extension CurrentUserControllerGeneric.BasePublishers: CurrentUserControllerDelegateGeneric {
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state.send(state)
    }
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) {
        self.unreadCount.send(unreadCount)
    }
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser currentUser: EntityChange<CurrentUserModel<ExtraData.User>>
    ) {
        currentUserChange.send(currentUser)
    }
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        connectionStatus.send(status)
    }
}
