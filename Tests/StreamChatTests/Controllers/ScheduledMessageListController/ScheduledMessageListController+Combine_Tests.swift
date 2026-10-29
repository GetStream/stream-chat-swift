//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ScheduledMessageListController_Combine_Tests: iOS13TestCase {
    var scheduledMessageListController: ScheduledMessageListController!
    var cancellables: Set<AnyCancellable>!
    var client: ChatClient_Mock!

    override func setUp() {
        super.setUp()
        client = ChatClient_Mock.mock
        scheduledMessageListController = ScheduledMessageListController(
            query: .init(),
            client: client
        )
        cancellables = []
    }

    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        weak var weakController = scheduledMessageListController
        scheduledMessageListController = nil
        wait(until: { weakController == nil })
        super.tearDown()
    }

    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()

        // Setup the chain
        scheduledMessageListController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        let controller = { [weak scheduledMessageListController] in scheduledMessageListController }
        scheduledMessageListController = nil

        controller()?.delegateCallback { $0.controller(controller()!, didChangeState: .remoteDataFetched) }

        XCTAssertEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_scheduledMessagesChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ScheduledMessage], Never>.Recording()

        // Setup the chain
        scheduledMessageListController
            .scheduledMessagesChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        let controller = { [weak scheduledMessageListController] in scheduledMessageListController }
        scheduledMessageListController = nil

        let cid = ChannelId.unique
        let scheduledMessage = ScheduledMessage(
            id: .unique,
            cid: cid,
            channel: ScheduledMessageChannel(cid: cid, name: nil, imageURL: nil),
            message: .unique,
            quotedMessageId: nil,
            scheduledAt: .unique,
            status: .scheduled,
            createdAt: .unique,
            updatedAt: .unique
        )
        controller()?.delegateCallback {
            $0.controller(controller()!, didChangeScheduledMessages: [scheduledMessage])
        }

        XCTAssertEqual(recording.output, [[scheduledMessage]])
    }
}
