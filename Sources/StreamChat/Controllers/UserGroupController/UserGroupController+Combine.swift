//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension UserGroupController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the user group changes.
    public var userGroupChangePublisher: AnyPublisher<EntityChange<UserGroup>, Never> {
        basePublishers.userGroupChange.keepAlive(self)
    }

    class BasePublishers {
        unowned let controller: UserGroupController

        let state: CurrentValueSubject<DataController.State, Never>
        let userGroupChange: PassthroughSubject<EntityChange<UserGroup>, Never> = .init()

        init(controller: UserGroupController) {
            self.controller = controller
            state = .init(controller.state)
            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension UserGroupController.BasePublishers: UserGroupControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func userGroupController(
        _ controller: UserGroupController,
        didUpdateUserGroup change: EntityChange<UserGroup>
    ) {
        userGroupChange.send(change)
    }
}
