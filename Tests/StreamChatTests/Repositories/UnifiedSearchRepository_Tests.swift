//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UnifiedSearchRepository_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var repository: UnifiedSearchRepository!

    override func setUp() {
        super.setUp()
        apiClient = APIClient_Spy()
        repository = UnifiedSearchRepository(apiClient: apiClient, modelsTransformer: nil)
    }

    override func tearDown() {
        apiClient.cleanUp()
        apiClient = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Request

    func test_search_makesCorrectAPICall() {
        let query = UnifiedSearchQuery(text: "ali", entities: [.messages, .users], pageSize: 5)
        let cursors: [UnifiedSearchEntity: String] = [.users: "u1"]
        let exp = expectation(description: "completion is called")

        repository.search(query: query, cursors: cursors, currentUserId: nil) { _ in
            exp.fulfill()
        }
        apiClient.test_simulateResponse(.success(SearchAllResponse()))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<SearchAllResponse> = .searchAll(
            searchAllRequest: query.asRequest(cursors: cursors),
            requiresConnectionId: false
        )
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), apiClient.request_endpoint)
        XCTAssertEqual("/api/v2/chat/search/all", apiClient.request_endpoint?.path.value)
        XCTAssertEqual(.post, apiClient.request_endpoint?.method)
        XCTAssertEqual(false, apiClient.request_endpoint?.requiresConnectionId)
    }

    func test_search_whenRequestFails_thenErrorIsReturned() async {
        let testError = TestError()
        apiClient.test_mockResponseResult(Result<SearchAllResponse, Error>.failure(testError))

        await XCTAssertAsyncFailure(
            try await repository.search(query: UnifiedSearchQuery(text: "ali"), currentUserId: nil),
            testError
        )
    }

    // MARK: - Conversion

    func test_search_convertsEverySection() async throws {
        let currentUserId: UserId = .unique
        let channelCid: ChannelId = .unique
        let hitCid: ChannelId = .unique
        let hitWithoutChannelCid: ChannelId = .unique
        let response = SearchAllResponse(
            channels: SearchAllChannelsSection(
                channels: [.dummy(channel: .dummy(cid: channelCid, name: "General"))],
                next: "channels-next"
            ),
            messages: SearchAllMessagesSection(
                next: "messages-next",
                results: [
                    SearchResult(message: .dummy(
                        messageId: "hit-1",
                        authorUserId: currentUserId,
                        cid: hitCid,
                        channel: .dummy(cid: hitCid, name: "Hit channel")
                    )),
                    SearchResult(message: .dummy(messageId: "hit-2", cid: hitWithoutChannelCid))
                ]
            ),
            users: SearchAllUsersSection(users: [.dummy(userId: "alice")])
        )
        apiClient.test_mockResponseResult(Result<SearchAllResponse, Error>.success(response))
        let query = UnifiedSearchQuery(text: "ali")

        let results = try await repository.search(query: query, currentUserId: currentUserId)

        XCTAssertEqual(query, results.query)
        XCTAssertEqual([channelCid], results.channels.items.map(\.cid))
        XCTAssertEqual("General", results.channels.items.first?.name)
        XCTAssertFalse(results.channels.hasLoadedAll)

        XCTAssertEqual(["hit-1", "hit-2"], results.messages.items.map(\.id))
        XCTAssertEqual(hitCid, results.messages.items[0].channel?.cid)
        XCTAssertEqual("Hit channel", results.messages.items[0].channel?.name)
        XCTAssertEqual(hitCid, results.messages.items[0].message.cid)
        XCTAssertTrue(results.messages.items[0].message.isSentByCurrentUser)
        XCTAssertNil(results.messages.items[1].channel)
        XCTAssertEqual(hitWithoutChannelCid, results.messages.items[1].message.cid)
        XCTAssertFalse(results.messages.items[1].message.isSentByCurrentUser)
        XCTAssertFalse(results.messages.hasLoadedAll)

        XCTAssertEqual(["alice"], results.users.items.map(\.id))
        XCTAssertTrue(results.users.hasLoadedAll)
    }

    func test_search_whenSectionsAreMissing_thenSectionsAreEmpty() async throws {
        apiClient.test_mockResponseResult(Result<SearchAllResponse, Error>.success(SearchAllResponse(
            users: SearchAllUsersSection()
        )))

        let results = try await repository.search(query: UnifiedSearchQuery(text: "ali"), currentUserId: nil)

        XCTAssertTrue(results.channels.items.isEmpty)
        XCTAssertTrue(results.channels.hasLoadedAll)
        XCTAssertTrue(results.messages.items.isEmpty)
        XCTAssertTrue(results.users.items.isEmpty)
        XCTAssertNil(results.users.error)
    }

    func test_search_whenSectionFails_thenErrorIsMappedAndOtherSectionsAreKept() async throws {
        apiClient.test_mockResponseResult(Result<SearchAllResponse, Error>.success(SearchAllResponse(
            channels: SearchAllChannelsSection(error: SearchAllSectionError(
                code: .backendTimeout,
                message: "channels search timed out"
            )),
            users: SearchAllUsersSection(users: [.dummy(userId: "alice")])
        )))

        let results = try await repository.search(query: UnifiedSearchQuery(text: "ali"), currentUserId: nil)

        XCTAssertEqual(.backendTimeout, results.channels.error?.code)
        XCTAssertEqual("channels search timed out", results.channels.error?.localizedDescription)
        XCTAssertTrue(results.channels.items.isEmpty)
        XCTAssertEqual(["alice"], results.users.items.map(\.id))
        XCTAssertNil(results.users.error)
    }

    func test_search_whenCursorIsRejected_thenSectionIsMarkedRestarted() async throws {
        apiClient.test_mockResponseResult(Result<SearchAllResponse, Error>.success(SearchAllResponse(
            users: SearchAllUsersSection(warning: SearchAllWarning(code: .cursorRejected))
        )))

        let results = try await repository.search(query: UnifiedSearchQuery(text: "ali"), currentUserId: nil)

        XCTAssertTrue(results.users.isRestarted)
        XCTAssertFalse(results.channels.isRestarted)
    }

    func test_search_whenModelsTransformerIsSet_thenChannelsAndMessagesAreTransformed() async throws {
        final class Transformer: StreamModelsTransformer, @unchecked Sendable {
            func transform(channel: ChatChannel) -> ChatChannel {
                channel.replacing(name: "transformed", imageURL: nil, extraData: nil)
            }

            func transform(message: ChatMessage) -> ChatMessage {
                message.replacing(text: "transformed", extraData: nil, attachments: nil)
            }
        }
        repository = UnifiedSearchRepository(apiClient: apiClient, modelsTransformer: Transformer())
        let hitCid: ChannelId = .unique
        apiClient.test_mockResponseResult(Result<SearchAllResponse, Error>.success(SearchAllResponse(
            channels: SearchAllChannelsSection(channels: [.dummy()]),
            messages: SearchAllMessagesSection(results: [
                SearchResult(message: .dummy(cid: hitCid, channel: .dummy(cid: hitCid)))
            ])
        )))

        let results = try await repository.search(query: UnifiedSearchQuery(text: "ali"), currentUserId: nil)

        XCTAssertEqual("transformed", results.channels.items.first?.name)
        XCTAssertEqual("transformed", results.messages.items.first?.channel?.name)
        XCTAssertEqual("transformed", results.messages.items.first?.message.text)
    }

    // MARK: - Decoding

    func test_searchAllJSON_isDecodedAndConverted() throws {
        let data = XCTestCase.mockData(fromJSONFile: "SearchAll")

        let response = try JSONDecoder.default.decode(SearchAllResponse.self, from: data)
        let results = response.asModel(query: UnifiedSearchQuery(text: "ali"), currentUserId: nil, modelsTransformer: nil)

        XCTAssertEqual(["messaging:general"], results.channels.items.map(\.cid.rawValue))
        XCTAssertTrue(results.channels.items.first?.lastActiveMembers.isEmpty == true)
        XCTAssertTrue(results.channels.hasLoadedAll)
        XCTAssertEqual(["7baa1533-3294-4c0c-9a62-c9d0928bf733"], results.messages.items.map(\.id))
        XCTAssertEqual("messaging:general", results.messages.items.first?.channel?.cid.rawValue)
        XCTAssertEqual("messages-next", results.messages.next)
        XCTAssertEqual(["broken-bush-1", "8160ad1a-da58-42ea-8d9a-d00b53a2d98e"], results.users.items.map(\.id))
        XCTAssertEqual("users-next", results.users.next)
    }

    func test_searchAllPartialFailureJSON_isDecodedAndConverted() throws {
        let data = XCTestCase.mockData(fromJSONFile: "SearchAllPartialFailure")

        let response = try JSONDecoder.default.decode(SearchAllResponse.self, from: data)
        let results = response.asModel(query: UnifiedSearchQuery(text: "ali"), currentUserId: nil, modelsTransformer: nil)

        XCTAssertEqual(.backendTimeout, results.messages.error?.code)
        XCTAssertTrue(results.messages.items.isEmpty)
        XCTAssertTrue(results.users.isRestarted)
        XCTAssertTrue(results.users.items.isEmpty)
        XCTAssertTrue(results.channels.items.isEmpty)
    }
}
