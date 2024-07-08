//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageSearch_Tests: XCTestCase {
    private var currentUserId: UserId!
    private var messageSearch: MessageSearch!
    private var env: TestEnvironment!
    private var testError: TestError!
    
    @MainActor override func setUpWithError() throws {
        currentUserId = UserId.unique
        testError = TestError()
        env = TestEnvironment()
        setUpMessageSearch(usesMockedMessageUpdater: true)
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        currentUserId = nil
        env = nil
        messageSearch = nil
        testError = nil
    }

    // MARK: - Searching Messages
    
    func test_searchText_whenTextMatchesAndLoggedIn_thenResultsAreReturnedAndStateUpdates() async throws {
        await setUpMessageSearch(usesMockedMessageUpdater: false)
        
        let apiResponse = makeMatchingResponse(messageCount: 1, createdAtOffset: 0)
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse))
        let results = try await messageSearch.search(text: "text")
        XCTAssertEqual(apiResponse.results.map(\.message.id), results.map(\.id))
        await MainActor.run {
            XCTAssertEqual(apiResponse.results.map(\.message.id), messageSearch.state.messages.map(\.id))
            XCTAssertEqual(messageSearch.explicitFilterHash, messageSearch.state.query?.filterHash)
            XCTAssertEqual([Sorting(key: .createdAt, isAscending: false)], messageSearch.state.query?.sort)
            XCTAssertEqual(Filter.containMembers(userIds: [currentUserId]), messageSearch.state.query?.channelFilter)
            XCTAssertEqual(Filter.autocomplete(.text, text: "text"), messageSearch.state.query?.messageFilter)
        }
    }
    
    func test_searchText_whenTextIsEmpty_thenResultsAndStateAreEmpty() async throws {
        await setUpMessageSearch(usesMockedMessageUpdater: false)
        
        // Initial search
        let apiResponse = makeMatchingResponse(messageCount: 1, createdAtOffset: 0)
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse))
        try await messageSearch.search(text: "text")
        
        // Next search should clear existing results
        let results = try await messageSearch.search(text: "")
        await MainActor.run {
            XCTAssertEqual(0, results.count)
            XCTAssertEqual(0, messageSearch.state.messages.count)
            XCTAssertNil(messageSearch.state.query)
        }
    }
    
    func test_searchText_whenNotLoggedIn_thenSearchingFails() async throws {
        env.client.mockAuthenticationRepository.mockedCurrentUserId = nil
        await XCTAssertAsyncFailure(try await messageSearch.search(text: "text")) { receivedError in
            receivedError is ClientError.CurrentUserDoesNotExist
        }
    }
    
    // MARK: - Results Pagination
    
    func test_loadMoreMessages_whenMoreResultsAreAvailable_thenResultsAndStateAreUpdated() async throws {
        await setUpMessageSearch(usesMockedMessageUpdater: false)
        let apiResponse = makeMatchingResponse(messageCount: 25, createdAtOffset: 0, next: "A")
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse))
        try await messageSearch.search(text: "text")
        await XCTAssertEqual(messageSearch.state.nextPageCursor, "A")
        
        let apiResponse2 = makeMatchingResponse(messageCount: 25, createdAtOffset: 25, next: "B")
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse2))
        let nextMessagesResult = try await messageSearch.loadMoreMessages()
        await MainActor.run {
            XCTAssertEqual(messageSearch.state.nextPageCursor, "B")
            XCTAssertEqual(apiResponse2.results.map(\.message.id), nextMessagesResult.map(\.id))
            let expected = apiResponse2.results + apiResponse.results
            XCTAssertEqual(expected.map(\.message.id), messageSearch.state.messages.map(\.id))
        }
    }
    
    // MARK: - Test Data
    
    @MainActor private func setUpMessageSearch(usesMockedMessageUpdater: Bool, loadState: Bool = true) {
        messageSearch = MessageSearch(
            client: env.client,
            environment: env.messageSearchEnvironment(usesMockedMessageUpdater: usesMockedMessageUpdater)
        )
        if loadState {
            _ = messageSearch.state
        }
    }
    
    private func makeMatchingResponse(messageCount: Int, createdAtOffset: Int, next: String? = nil) -> MessageSearchResultsPayload {
        // Default sorting is ascending false, mimic that in API responses
        let messagePayloads = (0..<messageCount)
            .reversed()
            .map {
                MessagePayload.dummy(
                    messageId: "\($0 + createdAtOffset)",
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0 + createdAtOffset)),
                    channel: .dummy(),
                    cid: .unique
                )
            }
        return MessageSearchResultsPayload(
            results: messagePayloads.map { MessagePayload.Boxed(message: $0) },
            next: next
        )
    }
}

extension MessageSearch_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var state: MessageSearchState!
        private(set) var messageUpdater: MessageUpdater!
        private(set) var messageUpdaterMock: MessageUpdater_Mock!
        
        func cleanUp() {
            client.cleanUp()
            messageUpdaterMock?.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
            messageUpdater = MessageUpdater(
                isLocalStorageEnabled: true,
                messageRepository: client.mockMessageRepository,
                database: client.mockDatabaseContainer,
                apiClient: client.mockAPIClient
            )
            messageUpdaterMock = MessageUpdater_Mock(
                isLocalStorageEnabled: true,
                messageRepository: client.mockMessageRepository,
                database: client.mockDatabaseContainer,
                apiClient: client.mockAPIClient
            )
        }
        
        func messageSearchEnvironment(usesMockedMessageUpdater: Bool) -> MessageSearch.Environment {
            MessageSearch.Environment(
                messageUpdaterBuilder: { [unowned self] in
                    self.messageUpdater = MessageUpdater(
                        isLocalStorageEnabled: $0,
                        messageRepository: $1,
                        database: $2,
                        apiClient: $3
                    )
                    self.messageUpdaterMock = MessageUpdater_Mock(
                        isLocalStorageEnabled: $0,
                        messageRepository: $1,
                        database: $2,
                        apiClient: $3
                    )
                    return usesMockedMessageUpdater ? messageUpdaterMock : messageUpdater
                },
                stateBuilder: { [unowned self] in
                    self.state = MessageSearchState(database: $0)
                    return self.state
                }
            )
        }
    }
}
