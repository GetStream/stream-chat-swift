//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension RoleSearchController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the list of roles changes.
    public var rolesChangesPublisher: AnyPublisher<[Role], Never> {
        basePublishers.rolesChanges.keepAlive(self)
    }

    class BasePublishers {
        unowned let controller: RoleSearchController

        let state: CurrentValueSubject<DataController.State, Never>
        let rolesChanges: PassthroughSubject<[Role], Never> = .init()

        init(controller: RoleSearchController) {
            self.controller = controller
            state = .init(controller.state)
            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension RoleSearchController.BasePublishers: RoleSearchControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func controller(
        _ controller: RoleSearchController,
        didChangeRoles roles: [Role]
    ) {
        rolesChanges.send(roles)
    }
}
