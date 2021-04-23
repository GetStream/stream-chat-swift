//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension _CurrentChatUserController {
    /// A publisher emitting a new value every time the current user changes.
    public var currentUserChangePublisher: AnyPublisher<EntityChange<_CurrentChatUser<ExtraData>>, Never> {
        basePublishers.currentUserChange.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the unread count changes..
    public var unreadCountPublisher: AnyPublisher<UnreadCount, Never> {
        basePublishers.unreadCount.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: _CurrentChatUserController
        
        /// A backing subject for `currentUserChangePublisher`.
        let currentUserChange: PassthroughSubject<EntityChange<_CurrentChatUser<ExtraData>>, Never> = .init()
        
        /// A backing subject for `unreadCountPublisher`.
        let unreadCount: CurrentValueSubject<UnreadCount, Never>
                
        init(controller: _CurrentChatUserController<ExtraData>) {
            self.controller = controller
            unreadCount = .init(.noUnread)
            
            controller.multicastDelegate.additionalDelegates.append(AnyCurrentUserControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _CurrentChatUserController.BasePublishers: _CurrentChatUserControllerDelegate {
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) {
        self.unreadCount.send(unreadCount)
    }
    
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser currentUser: EntityChange<_CurrentChatUser<ExtraData>>
    ) {
        currentUserChange.send(currentUser)
    }
}
