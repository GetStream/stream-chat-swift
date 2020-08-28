//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - CurrentUserControllerDelegateGeneric

final class AnyCurrentUserControllerDelegate<ExtraData: ExtraDataTypes>: CurrentUserControllerDelegateGeneric {
    weak var wrappedDelegate: AnyObject?
    private let _currentUserControllerDidChangeCurrentUserUnreadCount: (CurrentUserControllerGeneric<ExtraData>, UnreadCount)
        -> Void
    private let _currentUserControllerDidChangeCurrentUser: (
        CurrentUserControllerGeneric<ExtraData>,
        EntityChange<CurrentUserModel<ExtraData.User>>
    ) -> Void
    private let _controllerDidChangeState: (Controller, Controller.State) -> Void

    init(
        wrappedDelegate: AnyObject?,
        currentUserControllerDidChangeCurrentUserUnreadCount: @escaping (CurrentUserControllerGeneric<ExtraData>, UnreadCount)
            -> Void,
        currentUserControllerDidChangeCurrentUser: @escaping (
            CurrentUserControllerGeneric<ExtraData>,
            EntityChange<CurrentUserModel<ExtraData.User>>
        ) -> Void,
        controllerDidChangeState: @escaping (Controller, Controller.State) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _currentUserControllerDidChangeCurrentUserUnreadCount = currentUserControllerDidChangeCurrentUserUnreadCount
        _currentUserControllerDidChangeCurrentUser = currentUserControllerDidChangeCurrentUser
        _controllerDidChangeState = controllerDidChangeState
    }

    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUserUnreadCount count: UnreadCount
    ) {
        _currentUserControllerDidChangeCurrentUserUnreadCount(controller, count)
    }

    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser change: EntityChange<CurrentUserModel<ExtraData.User>>
    ) {
        _currentUserControllerDidChangeCurrentUser(controller, change)
    }

    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        _controllerDidChangeState(controller, state)
    }
}

extension AnyCurrentUserControllerDelegate {
    convenience init<Delegate: CurrentUserControllerDelegateGeneric>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            currentUserControllerDidChangeCurrentUserUnreadCount: { [weak delegate] (controller, count) in
                guard let delegate = delegate else { return }

                let function = delegate.currentUserController(_:didChangeCurrentUserUnreadCount:)
                let args = (controller, count)
                call(function, with: args)
            },
            currentUserControllerDidChangeCurrentUser: { [weak delegate] (controller, change) in
                guard let delegate = delegate else { return }

                let function = delegate.currentUserController(_:didChangeCurrentUser:)
                let args = (controller, change)
                call(function, with: args)
            },
            controllerDidChangeState: { [weak delegate] (controller, state) in
                guard let delegate = delegate else { return }

                let function = delegate.controller(_:didChangeState:)
                let args = (controller, state)
                call(function, with: args)
            }
        )
    }
}

private func call<T, U>(_ closure: (T) -> U, with args: T) -> U {
    closure(args)
}
