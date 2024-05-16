//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatThreadListController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var channelId: ChannelId!
    var controller: ChatThreadListController!
    var updaterMock: ThreadListUpdater_Mock!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        channelId = .unique
        updaterMock = ThreadListUpdater_Mock()
        controller = makeController(updater: updaterMock)
    }

    func test_synchronize_whenSuccess() {
        let exp = expectation(description: "synchronize completion")
        controller = makeController()
        controller.synchronize { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        XCTAssertEqual(updaterMock.loadThreadsCalledWith?.limit, controller.query.limit)

        updaterMock.loadThreadsCompletion?(.success([
            .mock(),
            .mock()
        ]))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(controller.state, .remoteDataFetched)
        XCTAssertTrue(controller.hasLoadedAllOlderThreads)
    }

    func test_synchronize_whenSuccess_whenMoreThreadsThanLimit() {
        let exp = expectation(description: "synchronize completion")
        var query = ThreadListQuery(watch: true)
        query.limit = 2
        controller = makeController(query: query)
        controller.synchronize { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        updaterMock.loadThreadsCompletion?(.success([
            .mock(),
            .mock(),
            .mock(),
            .mock()
        ]))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllOlderThreads)
    }

    func test_synchronize_whenFailure() {
        let exp = expectation(description: "synchronize completion")
        controller = makeController()
        controller.synchronize { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        updaterMock.loadThreadsCompletion?(.failure(ClientError()))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllOlderThreads)
        switch controller.state {
        case .remoteDataFetchFailed:
            break
        default:
            XCTFail()
        }
    }
    
    func test_loadOlderThreads_whenSuccess() {
        let exp = expectation(description: "loadOlderThreads completion")
        controller = makeController()
        controller.loadOlderThreads() { result in
            let threads = try? result.get()
            XCTAssertNotNil(threads)
            exp.fulfill()
        }
        XCTAssertEqual(updaterMock.loadThreadsCalledWith?.limit, controller.query.limit)

        updaterMock.loadThreadsCompletion?(.success([
            .mock(),
            .mock()
        ]))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(controller.hasLoadedAllOlderThreads)
    }

    func test_loadOlderThreads_whenSuccess_whenMoreThreadsThanLimit() {
        let exp = expectation(description: "loadOlderThreads completion")
        controller = makeController()
        controller.loadOlderThreads(limit: 2) { result in
            let threads = try? result.get()
            XCTAssertNotNil(threads)
            exp.fulfill()
        }
        XCTAssertEqual(updaterMock.loadThreadsCalledWith?.limit, 2)

        updaterMock.loadThreadsCompletion?(.success([
            .mock(),
            .mock(),
            .mock()
        ]))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllOlderThreads)
    }

    func test_loadOlderThreads_whenFailure() {
        let exp = expectation(description: "synchronize completion")
        controller = makeController()
        controller.loadOlderThreads() { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        updaterMock.loadThreadsCompletion?(.failure(ClientError()))

        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_observer_triggerDidChangeThreads_threadsHaveCorrectOrder() throws {
        class DelegateMock: ChatThreadListControllerDelegate {
            var threads: [ChatThread] = []
            func controller(
                _ controller: ChatThreadListController,
                didChangeThreads changes: [ListChange<ChatThread>]
            ) {
                threads = Array(controller.threads)
            }
        }

        let delegate = DelegateMock()
        controller.synchronize()
        controller.delegate = delegate

        try client.databaseContainer.writeSynchronously { session in
            let date = Date.unique
            session.saveThreadList(payload: .init(
                threads: [
                    .dummy(
                        parentMessageId: .unique,
                        updatedAt: date.addingTimeInterval(3),
                        title: "1"
                    ),
                    .dummy(
                        parentMessageId: .unique,
                        updatedAt: date.addingTimeInterval(2),
                        title: "2"
                    ),
                    .dummy(
                        parentMessageId: .unique,
                        updatedAt: date.addingTimeInterval(1),
                        title: "3"
                    )
                ],
                next: nil
            ))
        }

        XCTAssertEqual(controller.threads.count, 3)
        XCTAssertEqual(delegate.threads.map(\.title), ["1", "2", "3"])
    }
}

// MARK: - Helpers

extension ChatThreadListController_Tests {
    func makeController(
        query: ThreadListQuery = .init(watch: true),
        updater: ThreadListUpdater? = nil,
        observer: ListDatabaseObserverWrapper<ChatThread, ThreadDTO>? = nil
    ) -> ChatThreadListController {
        ChatThreadListController(
            query: query,
            client: client,
            environment: .init(
                threadListUpdaterBuilder: { _, _ in
                    updater ?? self.updaterMock
                },
                createThreadListDatabaseObserver: { _, database, fetchRequest, itemCreator in
                    observer ?? .init(
                        isBackground: false,
                        database: database,
                        fetchRequest: fetchRequest,
                        itemCreator: itemCreator
                    )
                }
            )
        )
    }
}
