//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

// #if !XCODE_BETA_1
// @available(iOS 13, *)
// extension CurrentChatUserController {
//    /// A publisher emitting a new value every time the current user changes.
//    public var currentUserChangePublisher: AnyPublisher<EntityChange<CurrentChatUser>, Never> {
//        basePublishers.currentUserChange.keepAlive(self)
//    }
//
//    /// A publisher emitting a new value every time the unread count changes..
//    public var unreadCountPublisher: AnyPublisher<UnreadCount, Never> {
//        basePublishers.unreadCount.keepAlive(self)
//    }
//
//    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
//    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
//    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
//    class BasePublishers {
//        /// The wrapper controller
//        unowned let controller: CurrentChatUserController
//
//        /// A backing subject for `currentUserChangePublisher`.
//        let currentUserChange: PassthroughSubject<EntityChange<CurrentChatUser>, Never> = .init()
//
//        /// A backing subject for `unreadCountPublisher`.
//        let unreadCount: CurrentValueSubject<UnreadCount, Never>
//
//        init(controller: CurrentChatUserController) {
//            self.controller = controller
//            unreadCount = .init(.noUnread)
//
//            controller.multicastDelegate.add(additionalDelegate: self)
//        }
//    }
// }
//
// @available(iOS 13, *)
// extension CurrentChatUserController.BasePublishers: CurrentChatUserControllerDelegate {
//    func currentUserController(
//        _ controller: CurrentChatUserController,
//        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
//    ) {
//        self.unreadCount.send(unreadCount)
//    }
//
//    func currentUserController(
//        _ controller: CurrentChatUserController,
//        didChangeCurrentUser currentUser: EntityChange<CurrentChatUser>
//    ) {
//        currentUserChange.send(currentUser)
//    }
// }
// #endif
