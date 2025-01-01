//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReactionListUpdater_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer!
    var reactionListUpdater: ReactionListUpdater!

    override func setUp() {
        super.setUp()

        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        reactionListUpdater = ReactionListUpdater(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()

        apiClient = nil
        reactionListUpdater = nil
        database = nil

        super.tearDown()
    }

    func test_loadReactions_whenSuccessful() throws {
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

        let payload = MessageReactionsPayload(reactions: [
            .dummy(messageId: messageId, user: .dummy(userId: .unique)),
            .dummy(messageId: messageId, user: .dummy(userId: .unique)),
            .dummy(messageId: messageId, user: .dummy(userId: .unique))
        ])
        let query = ReactionListQuery(
            messageId: messageId,
            pagination: .init(pageSize: 10, offset: 0),
            filter: .equal(.reactionType, to: "like")
        )

        let completionCalled = expectation(description: "completion called")
        reactionListUpdater.loadReactions(query: query) { result in
            XCTAssertNil(result.error)
            XCTAssertEqual(result.value?.count, 3)
            completionCalled.fulfill()
        }

        apiClient.test_simulateResponse(.success(payload))

        wait(for: [completionCalled], timeout: defaultTimeout)

        let referenceEndpoint: Endpoint<MessageReactionsPayload> = .loadReactionsV2(
            query: query
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))

        let loadedReactions = try payload.reactions.compactMap {
            try database.viewContext.reaction(messageId: messageId, userId: $0.user.id, type: $0.type)?.asModel()
        }
        XCTAssertEqual(loadedReactions.count, 3)
    }

    func test_loadReactions_whenFailure() throws {
        let messageId = MessageId.unique
        let query = ReactionListQuery(
            messageId: messageId,
            pagination: .init(pageSize: 10, offset: 0),
            filter: .equal(.reactionType, to: "like")
        )
        let completionCalled = expectation(description: "completion called")
        reactionListUpdater.loadReactions(query: query) { result in
            XCTAssertNotNil(result.error)
            completionCalled.fulfill()
        }

        let error = TestError()
        apiClient.test_simulateResponse(Result<MessageReactionsPayload, Error>.failure(error))

        wait(for: [completionCalled], timeout: defaultTimeout)

        let referenceEndpoint: Endpoint<MessageReactionsPayload> = .loadReactionsV2(
            query: query
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
}
