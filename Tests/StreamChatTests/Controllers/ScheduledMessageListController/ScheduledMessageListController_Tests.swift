//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ScheduledMessageListController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var cid: ChannelId!
    var userId: UserId!

    override func setUp() {
        super.setUp()

        client = ChatClient.mock
        cid = .unique
        userId = .unique
        client.currentUserId_mock = userId
        let simulator = ScheduledMessagesSimulator(client: client, responseDelay: 0, deliveryInterval: 3600)
        client.scheduledMessagesRepository = ScheduledMessagesRepository(client: client, simulator: simulator)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "io.getstream.chat.simulated-scheduled-messages.\(userId!)")
        client = nil
        cid = nil
        userId = nil

        super.tearDown()
    }

    func test_synchronize_loadsTheScheduledMessages() throws {
        let message = try schedule()
        let controller = client.scheduledMessageListController()

        let error = try waitFor { controller.synchronize($0) }

        XCTAssertNil(error)
        XCTAssertEqual(controller.state, .remoteDataFetched)
        XCTAssertTrue(controller.hasLoadedAllScheduledMessages)
        XCTAssertEqual(controller.scheduledMessages, [message])
    }

    @MainActor func test_delegate_isNotifiedOfInsertionsAndRemovals() throws {
        let controller = client.scheduledMessageListController()
        let delegate = DelegateSpy()
        controller.delegate = delegate

        delegate.expectation = expectation(description: "insertion")
        let message = try schedule()
        wait(for: [delegate.expectation!], timeout: defaultTimeout)

        guard case let .insert(inserted, index) = delegate.changes.last?.first else {
            return XCTFail("Expected an insertion")
        }
        XCTAssertEqual(inserted, message)
        XCTAssertEqual(index, IndexPath(item: 0, section: 0))

        delegate.expectation = expectation(description: "removal")
        _ = try waitFor { controller.deleteScheduledMessage(id: message.id, completion: $0) }
        wait(for: [delegate.expectation!], timeout: defaultTimeout)

        guard case .remove = delegate.changes.last?.first else {
            return XCTFail("Expected a removal")
        }
        XCTAssertEqual(controller.scheduledMessages, [])
    }

    func test_scheduledMessages_onlyIncludesTheMessagesMatchingTheQuery() throws {
        let message = try schedule()
        _ = try schedule(cid: .unique)

        let controller = client.scheduledMessageListController(query: .init(filter: .equal(.cid, to: cid)))

        XCTAssertEqual(controller.scheduledMessages, [message])
    }

    func test_rescheduleMessage_updatesTheDate() throws {
        let message = try schedule()
        let controller = client.scheduledMessageListController()
        let newDate = Date().addingTimeInterval(7200)

        let rescheduled = try waitFor { controller.rescheduleMessage(id: message.id, scheduledAt: newDate, completion: $0) }.get()

        XCTAssertEqual(rescheduled.scheduledAt, newDate)
        XCTAssertEqual(controller.scheduledMessages.first?.scheduledAt, newDate)
    }

    // MARK: - Helpers

    private func schedule(cid: ChannelId? = nil) throws -> ScheduledMessage {
        let channelController = client.channelController(for: cid ?? self.cid)
        return try waitFor {
            channelController.scheduleMessage(text: "Hello", scheduledAt: Date().addingTimeInterval(3600), completion: $0)
        }.get()
    }
}

private final class DelegateSpy: ScheduledMessageListControllerDelegate {
    var changes: [[ListChange<ScheduledMessage>]] = []
    var expectation: XCTestExpectation?

    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages changes: [ListChange<ScheduledMessage>]
    ) {
        self.changes.append(changes)
        expectation?.fulfill()
    }
}
