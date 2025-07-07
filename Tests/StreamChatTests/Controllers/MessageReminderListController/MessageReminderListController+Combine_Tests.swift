//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReminderListController_Combine_Tests: iOS13TestCase {
    var reminderListController: MessageReminderListController!
    var cancellables: Set<AnyCancellable>!
    var client: ChatClient_Mock!

    override func setUp() {
        super.setUp()
        client = ChatClient_Mock.mock
        reminderListController = MessageReminderListController(
            query: .init(),
            client: client
        )
        cancellables = []
    }

    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&reminderListController)
        reminderListController = nil
        super.tearDown()
    }

    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()

        // Setup the chain
        reminderListController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        nonisolated(unsafe) weak var controller: MessageReminderListController? = reminderListController
        reminderListController = nil

        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }

        AssertAsync.willBeEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_remindersChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<MessageReminder>], Never>.Recording()

        // Setup the chain
        reminderListController
            .remindersChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: MessageReminderListController? = reminderListController
        reminderListController = nil

        let reminder = MessageReminder(
            id: .unique,
            remindAt: nil,
            message: .unique,
            channel: .mock(cid: .unique),
            createdAt: .unique,
            updatedAt: .unique
        )
        let changes: [ListChange<MessageReminder>] = .init([.insert(reminder, index: .init())])
        controller?.delegateCallback {
            $0.controller(controller!, didChangeReminders: changes)
        }

        XCTAssertEqual(recording.output, .init(arrayLiteral: [.insert(reminder, index: .init())]))
    }
}
