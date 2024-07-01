//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadsRepository_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer!
    var repository: ThreadsRepository!

    override func setUp() {
        super.setUp()

        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        repository = ThreadsRepository(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()

        apiClient = nil
        repository = nil
        database = nil

        super.tearDown()
    }

    func test_loadThreads_whenSuccessful() throws {
        let messageId = MessageId.unique
        let channelId = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            try session.saveMessage(
                payload: .dummy(messageId: messageId),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
        }

        let payload = ThreadListPayload(
            threads: [
                .dummy(
                    parentMessageId: messageId,
                    channel: .dummy(cid: channelId),
                    replyCount: 3,
                    participantCount: 3,
                    threadParticipants: [
                        dummyThreadParticipantPayload(),
                        dummyThreadParticipantPayload(),
                        dummyThreadParticipantPayload()
                    ],
                    title: "Test",
                    latestReplies: [.dummy(), .dummy()],
                    read: [
                        dummyThreadReadPayload(unreadMessagesCount: 3),
                        dummyThreadReadPayload(unreadMessagesCount: 3)
                    ]
                ),
                .dummy(parentMessageId: .unique, channel: .dummy(cid: channelId)),
                .dummy(parentMessageId: .unique, channel: .dummy(cid: .unique))
            ],
            next: .unique
        )

        let query = ThreadListQuery(watch: true)
        let completionCalled = expectation(description: "completion called")
        repository.loadThreads(query: query) { result in
            XCTAssertNil(result.error)
            XCTAssertEqual(result.value?.threads.count, 3)
            completionCalled.fulfill()
        }

        apiClient.test_simulateResponse(.success(payload))

        wait(for: [completionCalled], timeout: defaultTimeout)

        let referenceEndpoint: Endpoint<ThreadListPayload> = .threads(
            query: query
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))

        let loadedThreads = payload.threads.map {
            database.viewContext.thread(parentMessageId: $0.parentMessageId, cache: nil)
        }
        XCTAssertEqual(loadedThreads.count, 3)
    }

    func test_loadThreads_whenFirstPage_deletesPreviousThreads() throws {
        let messageId = MessageId.unique
        let channelId = ChannelId.unique
        let previousThreads = [MessageId.unique, MessageId.unique]
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            try session.saveMessage(
                payload: .dummy(messageId: messageId),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
            // Save previous threads
            try previousThreads.forEach { previousThreadId in
                try session.saveThread(
                    payload: .dummy(parentMessageId: previousThreadId, channel: .dummy(cid: channelId)),
                    cache: nil
                )
            }
        }

        var loadedPreviousThreads: [ThreadDTO] {
            previousThreads.compactMap { database.viewContext.thread(parentMessageId: $0, cache: nil) }
        }
        XCTAssertEqual(loadedPreviousThreads.count, 2)

        let payload = ThreadListPayload(
            threads: [
                .dummy(parentMessageId: .unique, channel: .dummy(cid: .unique)),
                .dummy(parentMessageId: .unique, channel: .dummy(cid: .unique)),
                .dummy(parentMessageId: .unique, channel: .dummy(cid: .unique))
            ],
            next: nil
        )

        let query = ThreadListQuery(watch: true)
        let completionCalled = expectation(description: "completion called")
        repository.loadThreads(query: query) { result in
            XCTAssertNil(result.error)
            XCTAssertEqual(result.value?.threads.count, 3)
            completionCalled.fulfill()
        }

        apiClient.test_simulateResponse(.success(payload))
        wait(for: [completionCalled], timeout: defaultTimeout)

        let referenceEndpoint: Endpoint<ThreadListPayload> = .threads(
            query: query
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))

        let loadedThreads = payload.threads.map {
            database.viewContext.thread(parentMessageId: $0.parentMessageId, cache: nil)
        }
        XCTAssertEqual(loadedThreads.count, 3)
        XCTAssertEqual(loadedPreviousThreads.count, 0)
    }

    func test_loadThreads_whenFailure() throws {
        let query = ThreadListQuery(watch: true)
        let completionCalled = expectation(description: "completion called")
        repository.loadThreads(query: query) { result in
            XCTAssertNotNil(result.error)
            completionCalled.fulfill()
        }

        let error = TestError()
        apiClient.test_simulateResponse(Result<ThreadListPayload, Error>.failure(error))

        wait(for: [completionCalled], timeout: defaultTimeout)

        let referenceEndpoint: Endpoint<ThreadListPayload> = .threads(
            query: query
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
}
