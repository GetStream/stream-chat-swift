//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
                skipDraftUpdate: true,
                cache: nil
            )
        }

        let secondMessageId = MessageId.unique
        let thirdMessageId = MessageId.unique
        let payload = QueryThreadsResponse(
            threads: [
                .dummy(
                    channel: .dummy(cid: channelId),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: messageId),
                    parentMessageId: messageId,
                    participantCount: 3,
                    read: [
                        dummyThreadReadPayload(unreadMessagesCount: 3),
                        dummyThreadReadPayload(unreadMessagesCount: 3)
                    ],
                    replyCount: 3,
                    threadParticipants: [
                        dummyThreadParticipantPayload(),
                        dummyThreadParticipantPayload(),
                        dummyThreadParticipantPayload()
                    ],
                    title: "Test"
                ),
                .dummy(
                    channel: .dummy(cid: channelId),
                    parentMessage: .dummy(messageId: secondMessageId),
                    parentMessageId: secondMessageId
                ),
                .dummy(
                    channel: .dummy(cid: .unique),
                    parentMessage: .dummy(messageId: thirdMessageId),
                    parentMessageId: thirdMessageId
                )
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

        let request = QueryThreadsRequest(
            filter: nil,
            limit: query.limit,
            memberLimit: nil,
            next: query.next,
            participantLimit: query.participantLimit,
            prev: nil,
            replyLimit: query.replyLimit,
            sort: query.sort.map { SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.remoteKey) },
            watch: query.watch
        )
        let referenceEndpoint: Endpoint<QueryThreadsResponse> = .queryThreads(queryThreadsRequest: request)
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
                    payload: ThreadStateResponse.dummy(
                        channel: .dummy(cid: channelId),
                        parentMessage: .dummy(messageId: previousThreadId),
                        parentMessageId: previousThreadId
                    ),
                    cache: nil
                )
            }
        }

        var loadedPreviousThreads: [ThreadDTO] {
            previousThreads.compactMap { database.viewContext.thread(parentMessageId: $0, cache: nil) }
        }
        XCTAssertEqual(loadedPreviousThreads.count, 2)

        let firstPageThreadIds = [MessageId.unique, MessageId.unique, MessageId.unique]
        let payload = QueryThreadsResponse(
            threads: [
                .dummy(
                    channel: .dummy(cid: .unique),
                    parentMessage: .dummy(messageId: firstPageThreadIds[0]),
                    parentMessageId: firstPageThreadIds[0]
                ),
                .dummy(
                    channel: .dummy(cid: .unique),
                    parentMessage: .dummy(messageId: firstPageThreadIds[1]),
                    parentMessageId: firstPageThreadIds[1]
                ),
                .dummy(
                    channel: .dummy(cid: .unique),
                    parentMessage: .dummy(messageId: firstPageThreadIds[2]),
                    parentMessageId: firstPageThreadIds[2]
                )
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

        let request = QueryThreadsRequest(
            filter: nil,
            limit: query.limit,
            memberLimit: nil,
            next: query.next,
            participantLimit: query.participantLimit,
            prev: nil,
            replyLimit: query.replyLimit,
            sort: query.sort.map { SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.remoteKey) },
            watch: query.watch
        )
        let referenceEndpoint: Endpoint<QueryThreadsResponse> = .queryThreads(queryThreadsRequest: request)
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
        apiClient.test_simulateResponse(Result<QueryThreadsResponse, Error>.failure(error))

        wait(for: [completionCalled], timeout: defaultTimeout)

        let request = QueryThreadsRequest(
            filter: nil,
            limit: query.limit,
            memberLimit: nil,
            next: query.next,
            participantLimit: query.participantLimit,
            prev: nil,
            replyLimit: query.replyLimit,
            sort: query.sort.map { SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.remoteKey) },
            watch: query.watch
        )
        let referenceEndpoint: Endpoint<QueryThreadsResponse> = .queryThreads(queryThreadsRequest: request)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
}
