//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    @MainActor func test_observer_triggerDidChangeThreads_threadsHaveCorrectOrder() throws {
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
                        lastMessageAt: date.addingTimeInterval(30),
                        title: "1"
                    ),
                    .dummy(
                        parentMessageId: .unique,
                        lastMessageAt: date.addingTimeInterval(20),
                        title: "2"
                    ),
                    .dummy(
                        parentMessageId: .unique,
                        lastMessageAt: date.addingTimeInterval(1),
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

    // MARK: - Filter Predicate Tests

    func test_filterPredicate_channelDisabled_returnsExpectedResults() throws {
        let threadId1 = MessageId.unique
        let threadId2 = MessageId.unique
        let threadId3 = MessageId.unique

        try assertThreadFilterPredicate(
            .equal(.channelDisabled, to: true),
            threadsInDB: [
                .dummy(
                    parentMessageId: threadId1,
                    channel: .dummy(cid: .unique, isDisabled: true),
                    title: "Disabled Channel Thread 1"
                ),
                .dummy(
                    parentMessageId: threadId2,
                    channel: .dummy(cid: .unique, isDisabled: false),
                    title: "Enabled Channel Thread 1"
                ),
                .dummy(
                    parentMessageId: threadId3,
                    channel: .dummy(cid: .unique, isDisabled: true),
                    title: "Disabled Channel Thread 2"
                )
            ],
            expectedResult: [threadId1, threadId3]
        )
    }

    func test_filterPredicate_channelEnabled_returnsExpectedResults() throws {
        let threadId1 = MessageId.unique
        let threadId2 = MessageId.unique
        let threadId3 = MessageId.unique

        try assertThreadFilterPredicate(
            .equal(.channelDisabled, to: false),
            threadsInDB: [
                .dummy(
                    parentMessageId: threadId1,
                    channel: .dummy(cid: .unique, isDisabled: true),
                    title: "Disabled Channel Thread 1"
                ),
                .dummy(
                    parentMessageId: threadId2,
                    channel: .dummy(cid: .unique, isDisabled: false),
                    title: "Enabled Channel Thread 1"
                ),
                .dummy(
                    parentMessageId: threadId3,
                    channel: .dummy(cid: .unique, isDisabled: false),
                    title: "Enabled Channel Thread 2"
                )
            ],
            expectedResult: [threadId2, threadId3]
        )
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

    private func assertThreadFilterPredicate(
        _ filter: @autoclosure () -> Filter<ThreadListFilterScope>,
        sort: [Sorting<ThreadListSortingKey>] = [],
        threadsInDB: @escaping @autoclosure () -> [ThreadPayload],
        expectedResult: @autoclosure () -> [MessageId],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let query = ThreadListQuery(
            watch: true,
            filter: filter(),
            sort: sort
        )
        controller = makeController(query: query)
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Wait for initial threads update
        waitForInitialThreadsUpdate()
        
        XCTAssertEqual(controller.threads.map(\.parentMessageId), [], file: file, line: line)
        
        // Simulate changes in the DB:
        _ = try waitFor {
            client.databaseContainer.write({ session in
                session.saveThreadList(payload: .init(
                    threads: threadsInDB(),
                    next: nil
                ))
            }, completion: $0)
        }
        
        // Assert the resulting value is updated
        XCTAssertEqual(
            controller.threads.map(\.parentMessageId).sorted(),
            expectedResult().sorted(),
            file: file,
            line: line
        )
    }

    private func waitForInitialThreadsUpdate(file: StaticString = #file, line: UInt = #line) {
        waitForThreadsUpdate(file: file, line: line) {}
    }

    private func waitForThreadsUpdate(file: StaticString = #file, line: UInt = #line, block: () -> Void) {
        let threadsExpectation = expectation(description: "Threads update")
        StreamConcurrency.onMain {
            let delegate = ThreadsUpdateWaiter(threadsExpectation: threadsExpectation)
            controller.delegate = delegate
        }
        block()
        wait(for: [threadsExpectation], timeout: defaultTimeout)
    }
}

private class ThreadsUpdateWaiter: ChatThreadListControllerDelegate {
    weak var threadsExpectation: XCTestExpectation?

    var didChangeThreadsCount: Int?

    init(threadsExpectation: XCTestExpectation?) {
        self.threadsExpectation = threadsExpectation
    }

    func controller(_ controller: ChatThreadListController, didChangeThreads changes: [ListChange<ChatThread>]) {
        DispatchQueue.main.async {
            self.didChangeThreadsCount = controller.threads.count
            self.threadsExpectation?.fulfill()
        }
    }
}
