//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReminderListController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var controller: MessageReminderListController!
    var repositoryMock: RemindersRepository_Mock!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repositoryMock = client.remindersRepository as? RemindersRepository_Mock
        controller = makeController()
    }

    override func tearDown() {
        client.cleanUp()
        repositoryMock = nil
        controller = nil
        super.tearDown()
    }

    func test_synchronize_whenSuccess() {
        let exp = expectation(description: "synchronize completion")
        controller.synchronize { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        XCTAssertEqual(repositoryMock.loadReminders_callCount, 1)

        repositoryMock.loadReminders_completion?(.success(.init(reminders: [
            .mock(),
            .mock()
        ], next: nil)))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(controller.state, .remoteDataFetched)
        XCTAssertTrue(controller.hasLoadedAllReminders)
    }

    func test_synchronize_whenSuccess_whenMoreReminders() {
        let exp = expectation(description: "synchronize completion")
        var query = MessageReminderListQuery(pageSize: 2)
        controller = makeController(query: query)
        controller.synchronize { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        repositoryMock.loadReminders_completion?(.success(.init(reminders: [
            .mock(),
            .mock(),
            .mock(),
            .mock()
        ], next: .unique)))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllReminders)
    }

    func test_synchronize_whenFailure() {
        let exp = expectation(description: "synchronize completion")
        controller.synchronize { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        repositoryMock.loadReminders_completion?(.failure(ClientError()))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllReminders)
        switch controller.state {
        case .remoteDataFetchFailed:
            break
        default:
            XCTFail()
        }
    }

    func test_loadMoreReminders_whenSuccess() {
        let exp = expectation(description: "loadMoreReminders completion")
        controller.loadMoreReminders { result in
            let reminders = try? result.get()
            XCTAssertNotNil(reminders)
            exp.fulfill()
        }
        XCTAssertEqual(repositoryMock.loadReminders_query?.pagination.pageSize, controller.query.pagination.pageSize)

        repositoryMock.loadReminders_completion?(.success(.init(reminders: [
            .mock(),
            .mock()
        ])))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(controller.hasLoadedAllReminders)
    }

    func test_loadMoreReminders_whenSuccess_whenMoreReminders() {
        let exp = expectation(description: "loadMoreReminders completion")
        controller.loadMoreReminders(limit: 2) { result in
            let reminders = try? result.get()
            XCTAssertNotNil(reminders)
            exp.fulfill()
        }
        XCTAssertEqual(repositoryMock.loadReminders_query?.pagination.pageSize, 2)

        repositoryMock.loadReminders_completion?(.success(.init(reminders: [
            .mock(),
            .mock(),
            .mock()
        ], next: .unique)))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllReminders)
    }

    func test_loadMoreReminders_whenFailure() {
        let exp = expectation(description: "loadMoreReminders completion")
        controller.loadMoreReminders { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        repositoryMock.loadReminders_completion?(.failure(ClientError()))

        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_loadMoreReminders_shouldUseNextCursorWhenMorePagesAvailable() {
        let exp = expectation(description: "synchronize completion")
        controller.synchronize { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        let nextCursor1 = "cursor1"
        repositoryMock.loadReminders_completion?(.success(
            .init(reminders: [.mock(), .mock()], next: nextCursor1))
        )
        wait(for: [exp], timeout: defaultTimeout)

        let expMoreReminders = expectation(description: "loadMoreReminders1 completion")
        controller.loadMoreReminders { result in
            let reminders = try? result.get()
            XCTAssertNotNil(reminders)
            expMoreReminders.fulfill()
        }
        XCTAssertEqual(repositoryMock.loadReminders_query?.pagination.cursor, nextCursor1)

        let nextCursor2 = "cursor2"
        repositoryMock.loadReminders_completion?(.success(.init(
            reminders: [.mock(), .mock()], next: nextCursor2
        ))
        )
        wait(for: [expMoreReminders], timeout: defaultTimeout)

        controller.loadMoreReminders()
        XCTAssertEqual(repositoryMock.loadReminders_query?.pagination.cursor, nextCursor2)
    }

    func test_observer_triggerDidChangeReminders_remindersHaveCorrectOrder() throws {
        class DelegateMock: MessageReminderListControllerDelegate {
            var reminders: [MessageReminder] = []
            let expectation = XCTestExpectation(description: "Did Change Reminders")
            let expectedRemindersCount: Int
            
            init(expectedRemindersCount: Int) {
                self.expectedRemindersCount = expectedRemindersCount
            }
            
            func controller(
                _ controller: MessageReminderListController,
                didChangeReminders changes: [ListChange<MessageReminder>]
            ) {
                reminders = Array(controller.reminders)
                guard expectedRemindersCount == reminders.count else { return }
                expectation.fulfill()
            }
        }

        let delegate = DelegateMock(expectedRemindersCount: 3)
        controller.synchronize()
        controller.delegate = delegate

        try client.databaseContainer.writeSynchronously { session in
            let date = Date.unique
            let cid = ChannelId.unique
            let messageId1 = MessageId.unique
            let messageId2 = MessageId.unique
            let messageId3 = MessageId.unique
            
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .admin))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveMessage(payload: .dummy(messageId: messageId1), for: cid, syncOwnReactions: false, cache: nil)
            try session.saveMessage(payload: .dummy(messageId: messageId2), for: cid, syncOwnReactions: false, cache: nil)
            try session.saveMessage(payload: .dummy(messageId: messageId3), for: cid, syncOwnReactions: false, cache: nil)

            let reminders = [
                ReminderPayload(
                    channelCid: cid,
                    messageId: messageId1,
                    remindAt: date.addingTimeInterval(3),
                    createdAt: date,
                    updatedAt: date
                ),
                ReminderPayload(
                    channelCid: cid,
                    messageId: messageId2,
                    remindAt: date.addingTimeInterval(2),
                    createdAt: date,
                    updatedAt: date
                ),
                ReminderPayload(
                    channelCid: cid,
                    messageId: messageId3,
                    remindAt: date.addingTimeInterval(1),
                    createdAt: date,
                    updatedAt: date
                )
            ]

            try reminders.forEach {
                try session.saveReminder(payload: $0, cache: nil)
            }
        }
        wait(for: [delegate.expectation], timeout: defaultTimeout)
        XCTAssertEqual(controller.reminders.count, 3)
        XCTAssertEqual(delegate.reminders.count, 3)
    }
}

// MARK: - Helpers

extension MessageReminderListController_Tests {
    func makeController(
        query: MessageReminderListQuery = .init(),
        repository: RemindersRepository? = nil,
        observer: BackgroundListDatabaseObserver<MessageReminder, MessageReminderDTO>? = nil
    ) -> MessageReminderListController {
        MessageReminderListController(
            query: query,
            client: client,
            environment: .init(
                createMessageReminderListDatabaseObserver: { database, fetchRequest, itemCreator in
                    observer ?? BackgroundListDatabaseObserver(
                        database: database,
                        fetchRequest: fetchRequest,
                        itemCreator: itemCreator,
                        itemReuseKeyPaths: nil
                    )
                }
            )
        )
    }
}

private extension MessageReminder {
    static func mock(
        id: String = .unique,
        remindAt: Date? = nil,
        message: ChatMessage = .mock(),
        channel: ChatChannel = .mockDMChannel(),
        createdAt: Date = .unique,
        updatedAt: Date = .unique
    ) -> MessageReminder {
        .init(
            id: id,
            remindAt: remindAt,
            message: message,
            channel: channel,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
