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
    var repositoryMock: ThreadsRepository_Mock!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        channelId = .unique
        repositoryMock = ThreadsRepository_Mock()
        controller = makeController()
    }

    func test_synchronize_whenSuccess() {
        let exp = expectation(description: "synchronize completion")
        controller.synchronize { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        XCTAssertEqual(repositoryMock.loadThreadsCalledWith?.limit, controller.query.limit)

        repositoryMock.loadThreadsCompletion?(.success(.init(threads: [
            .mock(),
            .mock()
        ])))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(controller.state, .remoteDataFetched)
        XCTAssertTrue(controller.hasLoadedAllThreads)
    }

    func test_synchronize_whenSuccess_whenMoreThreads() {
        let exp = expectation(description: "synchronize completion")
        var query = ThreadListQuery(watch: true)
        query.limit = 2
        controller = makeController(query: query)
        controller.synchronize { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        repositoryMock.loadThreadsCompletion?(.success(.init(threads: [
            .mock(),
            .mock(),
            .mock(),
            .mock()
        ], next: .unique)))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllThreads)
    }

    func test_synchronize_whenFailure() {
        let exp = expectation(description: "synchronize completion")
        controller.synchronize { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        repositoryMock.loadThreadsCompletion?(.failure(ClientError()))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllThreads)
        switch controller.state {
        case .remoteDataFetchFailed:
            break
        default:
            XCTFail()
        }
    }
    
    func test_loadMoreThreads_whenSuccess() {
        let exp = expectation(description: "loadOlderThreads completion")
        controller.loadMoreThreads() { result in
            let threads = try? result.get()
            XCTAssertNotNil(threads)
            exp.fulfill()
        }
        XCTAssertEqual(repositoryMock.loadThreadsCalledWith?.limit, controller.query.limit)

        repositoryMock.loadThreadsCompletion?(.success(.init(threads: [
            .mock(),
            .mock()
        ])))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(controller.hasLoadedAllThreads)
    }

    func test_loadMoreThreads_whenSuccess_whenMoreThreads() {
        let exp = expectation(description: "loadOlderThreads completion")
        controller.loadMoreThreads(limit: 2) { result in
            let threads = try? result.get()
            XCTAssertNotNil(threads)
            exp.fulfill()
        }
        XCTAssertEqual(repositoryMock.loadThreadsCalledWith?.limit, 2)

        repositoryMock.loadThreadsCompletion?(.success(.init(threads: [
            .mock(),
            .mock(),
            .mock()
        ], next: .unique)))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllThreads)
    }

    func test_loadMoreThreads_whenFailure() {
        let exp = expectation(description: "synchronize completion")
        controller.loadMoreThreads() { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        repositoryMock.loadThreadsCompletion?(.failure(ClientError()))

        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_loadMoreThreads_shouldUseNextCursorWhenMorePagesAvailable() {
        let exp = expectation(description: "synchronize completion")
        controller.synchronize { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        let nextCursor1 = "cursor1"
        repositoryMock.loadThreadsCompletion?(.success(
            .init(threads: [.mock(), .mock()], next: nextCursor1))
        )
        wait(for: [exp], timeout: defaultTimeout)

        let expOlderThreads = expectation(description: "loadOlderThreads1 completion")
        controller.loadMoreThreads() { result in
            let threads = try? result.get()
            XCTAssertNotNil(threads)
            expOlderThreads.fulfill()
        }
        XCTAssertEqual(repositoryMock.loadThreadsCalledWith?.next, nextCursor1)

        let nextCursor2 = "cursor2"
        repositoryMock.loadThreadsCompletion?(.success(.init(
            threads: [.mock(), .mock()], next: nextCursor2
        ))
        )
        wait(for: [expOlderThreads], timeout: defaultTimeout)

        controller.loadMoreThreads()
        XCTAssertEqual(repositoryMock.loadThreadsCalledWith?.next, nextCursor2)
    }

    func test_observer_triggerDidChangeThreads_threadsHaveCorrectOrder() throws {
        class DelegateMock: ChatThreadListControllerDelegate {
            var threads: [ChatThread] = []
            let expectation = XCTestExpectation(description: "Did Change Threads")
            let expectedThreadsCount: Int
            
            init(expectedThreadsCount: Int) {
                self.expectedThreadsCount = expectedThreadsCount
            }
            
            func controller(
                _ controller: ChatThreadListController,
                didChangeThreads changes: [ListChange<ChatThread>]
            ) {
                threads = Array(controller.threads)
                guard expectedThreadsCount == threads.count else { return }
                expectation.fulfill()
            }
        }

        let delegate = DelegateMock(expectedThreadsCount: 3)
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
        wait(for: [delegate.expectation], timeout: defaultTimeout)
        XCTAssertEqual(controller.threads.count, 3)
        XCTAssertEqual(delegate.threads.map(\.title), ["1", "2", "3"])
    }
}

// MARK: - Helpers

extension ChatThreadListController_Tests {
    func makeController(
        query: ThreadListQuery = .init(watch: true),
        repository: ThreadsRepository? = nil,
        observer: BackgroundListDatabaseObserver<ChatThread, ThreadDTO>? = nil
    ) -> ChatThreadListController {
        ChatThreadListController(
            query: query,
            client: client,
            environment: .init(
                threadsRepositoryBuilder: { _, _ in
                    self.repositoryMock
                },
                createThreadListDatabaseObserver: { database, fetchRequest, itemCreator in
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
