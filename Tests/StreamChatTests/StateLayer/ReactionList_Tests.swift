//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReactionList_Tests: XCTestCase {
    private var channelId: ChannelId!
    private var messageId: MessageId!
    private var reactionList: ReactionList!
    private var env: TestEnvironment!
    private var query: ReactionListQuery!
    
    override func setUpWithError() throws {
        channelId = .unique
        messageId = .unique
        env = TestEnvironment()
        query = ReactionListQuery(messageId: messageId)
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        env = nil
        reactionList = nil
        query = nil
    }
    
    // MARK: - Restoring State

    func test_restoreState_whenDatabaseHasItems_thenStateIsUpToDate() async throws {
        try await createChannel()
        let initialPayload = makeMessageReactionsPayload(
            reactionCount: 5,
            offset: 0,
            messageId: messageId
        )
        try await env.client.databaseContainer.write { session in
            session.saveReactions(payload: initialPayload, query: self.query)
        }
        try await setUpReactionList()
        await XCTAssertEqual(
            initialPayload.reactions.map(\.type.rawValue),
            reactionList.state.reactions.map(\.type.rawValue)
        )
    }

    // MARK: - Get
    
    func test_get_whenLocalStoreHasReactions_thenGetResetsReactions() async throws {
        // Existing state
        try await createChannel()
        let initialPayload = makeMessageReactionsPayload(
            reactionCount: 3,
            offset: 0,
            messageId: messageId
        )
        try await env.client.databaseContainer.write { session in
            session.saveReactions(payload: initialPayload, query: self.query)
        }
        
        try await setUpReactionList()
        await XCTAssertEqual(3, reactionList.state.reactions.count)
        
        let nextPayload = makeMessageReactionsPayload(
            reactionCount: 2,
            offset: 0,
            messageId: messageId
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(nextPayload))
        try await reactionList.get()
        
        // TODO: Reset is not implemented (if it is, the result should be 2)
        await XCTAssertEqual(5, reactionList.state.reactions.count)
//        await XCTAssertEqual(
//            nextPayload.reactions.map(\.type.rawValue),
//            reactionList.state.reactions.map(\.type.rawValue)
//        )
    }
    
    func test_get_whenLocalStoreHasReactions_thenGetFetchesFirstPageOfReactions() async throws {
        try await createChannel()
        try await setUpReactionList()
        await XCTAssertEqual(0, reactionList.state.reactions.count)
        
        let nextPayload = makeMessageReactionsPayload(
            reactionCount: 3,
            offset: 0,
            messageId: messageId
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(nextPayload))
        try await reactionList.get()
        
        await XCTAssertEqual(3, reactionList.state.reactions.count)
        await XCTAssertEqual(
            nextPayload.reactions.map(\.type.rawValue),
            reactionList.state.reactions.map(\.type.rawValue)
        )
    }
    
    // MARK: - Pagination
    
    func test_loadReactions_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        try await createChannel()
        try await setUpReactionList()
        
        let apiResult = makeMessageReactionsPayload(
            reactionCount: 10,
            offset: 0,
            messageId: messageId
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let pagination = Pagination(pageSize: 10)
        let result = try await reactionList.loadReactions(with: pagination)
        XCTAssertEqual(
            apiResult.reactions.map(\.type.rawValue),
            result.map(\.type.rawValue)
        )
        await XCTAssertEqual(
            apiResult.reactions.map(\.type.rawValue),
            reactionList.state.reactions.map(\.type.rawValue)
        )
    }
    
    func test_loadMoreReactions_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        try await createChannel()
        try await setUpReactionList()
        
        let initialPayload = makeMessageReactionsPayload(
            reactionCount: 5,
            offset: 3,
            messageId: messageId
        )
        try await env.client.databaseContainer.write { session in
            session.saveReactions(payload: initialPayload, query: self.query)
        }
        
        let apiResult = makeMessageReactionsPayload(
            reactionCount: 3,
            offset: 0,
            messageId: messageId
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let result = try await reactionList.loadMoreReactions(limit: 3)
        XCTAssertEqual(apiResult.reactions.map(\.type.rawValue), result.map(\.type.rawValue))
        
        let allExpectedIds = (initialPayload.reactions + apiResult.reactions).map(\.type.rawValue)
        await XCTAssertEqual(allExpectedIds, reactionList.state.reactions.map(\.type.rawValue))
    }

    // MARK: - Test Data
    
    @MainActor private func setUpReactionList(loadState: Bool = true) async throws {
        reactionList = ReactionList(
            query: query,
            client: env.client,
            environment: env.reactionListEnvironment()
        )
        if loadState {
            _ = reactionList.state
        }
    }
    
    private func createChannel() async throws {
        try await env.client.databaseContainer.write { session in
            try session.saveChannel(
                payload: ChannelPayload.dummy(
                    channel: .dummy(cid: self.channelId),
                    messages: [
                        .dummy(messageId: self.messageId)
                    ]
                )
            )
        }
    }
    
    private func makeMessageReactionsPayload(
        reactionCount: Int,
        offset: Int,
        messageId: MessageId
    ) -> MessageReactionsPayload {
        let reactions = (0..<reactionCount)
            .map { $0 + offset }
            .reversed() // last updated ones first
            .map {
                MessageReactionPayload.dummy(
                    messageId: messageId,
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0)),
                    updatedAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0)),
                    user: .dummy(userId: .unique)
                )
            }
        return MessageReactionsPayload(reactions: reactions)
    }
}

extension ReactionList_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var reactionListUpdater: ReactionListUpdater!
        
        func cleanUp() {
            client.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
        }
        
        func reactionListEnvironment() -> ReactionList.Environment {
            ReactionList.Environment(
                reactionListUpdaterBuilder: { [unowned self] in
                    self.reactionListUpdater = ReactionListUpdater(
                        database: $0,
                        apiClient: $1
                    )
                    return reactionListUpdater
                }
            )
        }
    }
}
