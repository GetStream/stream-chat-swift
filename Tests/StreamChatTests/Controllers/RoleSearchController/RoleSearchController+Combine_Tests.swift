//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RoleSearchController_Combine_Tests: iOS13TestCase {
    var roleSearchController: RoleSearchController!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        roleSearchController = .init(client: .mock)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        AssertAsync.canBeReleased(&roleSearchController)
        roleSearchController = nil
        super.tearDown()
    }

    func test_statePublisher() {
        var recording = Record<DataController.State, Never>.Recording()

        roleSearchController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        let controller = { [weak roleSearchController] in roleSearchController }
        roleSearchController = nil

        controller()?.delegateCallback { [controller = controller()] in $0.controller(controller!, didChangeState: .remoteDataFetched) }

        XCTAssertEqual(recording.output, [.initialized, .remoteDataFetched])
    }

    func test_rolesChangesPublisher() {
        var recording = Record<[Role], Never>.Recording()

        roleSearchController
            .rolesChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        let controller = { [weak roleSearchController] in roleSearchController }
        roleSearchController = nil

        let roles = [Role.dummy(name: "admin")]
        controller()?.delegateCallback { [controller = controller()] in
            $0.controller(controller!, didChangeRoles: roles)
        }

        XCTAssertEqual(recording.output.last, roles)
    }
}
