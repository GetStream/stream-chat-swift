//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension UserGroupListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the list of user groups changes.
    public var userGroupsChangesPublisher: AnyPublisher<[ListChange<UserGroup>], Never> {
        basePublishers.userGroupsChanges.keepAlive(self)
    }

    class BasePublishers {
        unowned let controller: UserGroupListController

        let state: CurrentValueSubject<DataController.State, Never>
        let userGroupsChanges: PassthroughSubject<[ListChange<UserGroup>], Never> = .init()

        init(controller: UserGroupListController) {
            self.controller = controller
            state = .init(controller.state)
            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension UserGroupListController.BasePublishers: UserGroupListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func controller(
        _ controller: UserGroupListController,
        didChangeUserGroups changes: [ListChange<UserGroup>]
    ) {
        userGroupsChanges.send(changes)
    }
}
