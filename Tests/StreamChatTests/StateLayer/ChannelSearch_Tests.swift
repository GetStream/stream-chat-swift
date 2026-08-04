//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelSearch_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var channelSearch: ChannelSearch!
    private var currentUserId: UserId!

    @MainActor override func setUpWithError() throws {
        env = TestEnvironment()
        currentUserId = .unique
        env.client.currentUserId_mock = currentUserId
        // Keep search synchronous unless a test opts into debouncing.
        channelSearch = env.makeChannelSearch(debouncePolicy: .constant(0))
        _ = channelSearch.state
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        env = nil
        channelSearch = nil
        currentUserId = nil
    }

    // MARK: - Searching Channels

    func test_search_fetchesTheMatchingChannelList() async throws {
        try await channelSearch.search(text: "gen")

        // Channel contents come from the channel list's database observer, which ChannelList
        // already covers. What matters here is that the search drove exactly one fetch.
        XCTAssertEqual(1, env.builtQueries.count)
        XCTAssertEqual(1, env.channelListUpdaterSpy.update_queries.count)
    }

    func test_search_buildsAnAutocompleteQueryScopedToTheCurrentUser() async throws {
        try await channelSearch.search(text: "general")

        let currentUserId = try XCTUnwrap(currentUserId)
        try await MainActor.run {
            let query = try XCTUnwrap(channelSearch.state.query)
            XCTAssertEqual(
                "(name AUTOCOMPLETE general) AND (members IN [\"\(currentUserId)\"])",
                query.filter.filterHash
            )
            // Searched channels must not be watched.
            XCTAssertTrue(query.options.isEmpty)
        }
    }

    func test_search_whenTextIsEmpty_thenStateIsCleared() async throws {
        try await channelSearch.search(text: "general")
        await MainActor.run { XCTAssertNotNil(channelSearch.state.query) }

        let result = try await channelSearch.search(text: "  ")

        XCTAssertTrue(result.isEmpty)
        await MainActor.run {
            XCTAssertEqual(0, channelSearch.state.channels.count)
            XCTAssertNil(channelSearch.state.query)
        }
    }

    func test_search_whenCurrentUserIsMissing_thenItThrows() async throws {
        env.client.currentUserId_mock = nil

        await XCTAssertAsyncFailure(
            try await channelSearch.search(text: "general"),
            expectedErrorHandler: { $0 is ClientError.CurrentUserDoesNotExist }
        )
    }

    // MARK: - Debouncing

    func test_search_whenTypingRapidly_thenOnlyTheLastSearchIsPerformed() async throws {
        channelSearch = await env.makeChannelSearch(debouncePolicy: .constant(0.15))

        async let first: Void = { _ = try await channelSearch.search(text: "gen") }()
        try await Task.sleep(nanoseconds: 10_000_000)
        async let second: Void = { _ = try await channelSearch.search(text: "general") }()

        _ = try await (first, second)

        XCTAssertEqual(1, env.builtQueries.count)
        XCTAssertTrue(env.builtQueries[0].filter.filterHash.contains("general"))
    }

    func test_search_whenSuperseded_thenItReturnsCurrentResultsWithoutThrowing() async throws {
        channelSearch = await env.makeChannelSearch(debouncePolicy: .constant(0.15))

        async let superseded = channelSearch.search(text: "gen")
        try await Task.sleep(nanoseconds: 10_000_000)
        async let winner = channelSearch.search(text: "general")

        // Typing must not surface an error per keystroke.
        let supersededResult = try await superseded
        let winnerResult = try await winner
        XCTAssertEqual(winnerResult.map(\.cid), supersededResult.map(\.cid))
    }

    // MARK: - Pagination

    func test_loadMoreChannels_withoutSearch_thenItThrows() async throws {
        await XCTAssertAsyncFailure(
            try await channelSearch.loadMoreChannels(),
            expectedErrorHandler: { $0 is ClientError }
        )
    }
}

extension ChannelSearch_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var channelListUpdaterSpy: ChannelListUpdater_Spy!
        private(set) var builtQueries: [ChannelListQuery] = []

        init() {
            client = ChatClient_Mock(config: ChatClient_Mock.defaultMockedConfig)
        }

        func cleanUp() {
            client.cleanUp()
            channelListUpdaterSpy?.cleanUp()
        }

        @MainActor func makeChannelSearch(debouncePolicy: SearchDebouncePolicy) -> ChannelSearch {
            let search = ChannelSearch(
                client: client,
                debouncePolicy: debouncePolicy,
                environment: .init(channelListBuilder: { [unowned self] query, client in
                    builtQueries.append(query)
                    return ChannelList(
                        query: query,
                        dynamicFilter: nil,
                        client: client,
                        environment: .init(
                            channelListUpdater: { [unowned self] database, apiClient in
                                channelListUpdaterSpy = ChannelListUpdater_Spy(
                                    database: database,
                                    apiClient: apiClient
                                )
                                channelListUpdaterSpy.update_completion_result = .success([])
                                return channelListUpdaterSpy
                            }
                        )
                    )
                })
            )
            _ = search.state
            return search
        }
    }
}
