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
            XCTAssertNotNil(query.explicitQueryHash)
        }
    }

    func test_searchQuery_usesProvidedPageSize() async throws {
        let currentUserId = try XCTUnwrap(currentUserId)
        var query = ChannelListQuery(
            filter: .and([
                .autocomplete(.name, text: "general"),
                .containMembers(userIds: [currentUserId])
            ]),
            pageSize: 3
        )
        query.options = []

        try await channelSearch.search(query: query)

        XCTAssertEqual(3, env.channelListUpdaterSpy.update_queries.last?.pagination.pageSize)
    }

    func test_searchQuery_appliesExplicitQueryHash() async throws {
        let currentUserId = try XCTUnwrap(currentUserId)
        var query = ChannelListQuery(
            filter: .and([
                .autocomplete(.name, text: "general"),
                .containMembers(userIds: [currentUserId])
            ])
        )
        query.options = []

        try await channelSearch.search(query: query)

        try await MainActor.run {
            let storedQuery = try XCTUnwrap(channelSearch.state.query)
            XCTAssertNotNil(storedQuery.explicitQueryHash)
        }
    }

    func test_searchQuery_resetsPaginationToTheFirstPage() async throws {
        let currentUserId = try XCTUnwrap(currentUserId)
        try await channelSearch.search(text: "general")
        try writeChannel(cid: .unique, name: "general", query: try await MainActor.run {
            try XCTUnwrap(channelSearch.state.query)
        })
        try await waitForChannels { $0.count == 1 }
        try await channelSearch.loadMoreChannels(limit: 10)

        var query = ChannelListQuery(
            filter: .and([
                .autocomplete(.name, text: "general"),
                .containMembers(userIds: [currentUserId])
            ]),
            pageSize: 3
        )
        query.options = []
        try await channelSearch.search(query: query)

        let paginationQuery = try XCTUnwrap(env.channelListUpdaterSpy.update_queries.last)
        XCTAssertEqual(0, paginationQuery.pagination.offset)
        XCTAssertEqual(3, paginationQuery.pagination.pageSize)
    }

    func test_search_alwaysQueriesTheFirstPage() async throws {
        // An initial fetch is what makes the updater replace the previously linked results.
        try await channelSearch.search(text: "gen")
        try await channelSearch.search(text: "general")

        let paginations = env.channelListUpdaterSpy.update_queries.map(\.pagination)
        XCTAssertEqual(2, paginations.count)
        XCTAssertEqual(2, paginations.filter { $0.offset == 0 && $0.cursor == nil }.count)
    }

    func test_search_whenTextIsEmpty_thenStateIsCleared() async throws {
        try await channelSearch.search(text: "general")
        let searchQuery = try await MainActor.run { try XCTUnwrap(channelSearch.state.query) }
        try writeChannel(cid: .unique, name: "general", query: searchQuery)
        try await waitForChannels { !$0.isEmpty }

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

    // MARK: - Results

    func test_channels_reportsChannelsLinkedToTheSearchQuery() async throws {
        try await channelSearch.search(text: "general")
        let searchQuery = try await MainActor.run { try XCTUnwrap(channelSearch.state.query) }

        let cid = ChannelId.unique
        try writeChannel(cid: cid, name: "general", query: searchQuery)

        try await waitForChannels { $0.map(\.cid) == [cid] }
    }

    func test_channels_areUpdatedWhenALinkedChannelChanges() async throws {
        try await channelSearch.search(text: "general")
        let searchQuery = try await MainActor.run { try XCTUnwrap(channelSearch.state.query) }

        let cid = ChannelId.unique
        try writeChannel(cid: cid, name: "general", query: searchQuery)
        try await waitForChannels { $0.map(\.cid) == [cid] }

        // The channel is updated without being re-linked to the query.
        try writeChannel(cid: cid, name: "general channel", query: nil)

        try await waitForChannels { $0.first?.name == "general channel" }
    }

    // MARK: - Debouncing

    func test_search_whenTypingRapidly_thenOnlyTheLastSearchIsPerformed() async throws {
        channelSearch = await env.makeChannelSearch(debouncePolicy: .constant(0.15))

        async let first: Void = { _ = try await channelSearch.search(text: "gen") }()
        try await Task.sleep(nanoseconds: 10_000_000)
        async let second: Void = { _ = try await channelSearch.search(text: "general") }()

        _ = try await (first, second)

        let queries = env.channelListUpdaterSpy.update_queries
        XCTAssertEqual(1, queries.count)
        XCTAssertTrue(queries[0].filter.filterHash.contains("general"))
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

    func test_loadMoreChannels_paginatesTheCurrentSearchQuery() async throws {
        try await channelSearch.search(text: "general")
        let searchQuery = try await MainActor.run { try XCTUnwrap(channelSearch.state.query) }
        try writeChannel(cid: .unique, name: "general", query: searchQuery)
        try await waitForChannels { $0.count == 1 }

        try await channelSearch.loadMoreChannels(limit: 10)

        let paginationQuery = try XCTUnwrap(env.channelListUpdaterSpy.update_queries.last)
        XCTAssertEqual(searchQuery.queryHash, paginationQuery.queryHash)
        XCTAssertEqual(10, paginationQuery.pagination.pageSize)
        XCTAssertEqual(1, paginationQuery.pagination.offset)
    }

    // MARK: - Helpers

    private func writeChannel(cid: ChannelId, name: String, query: ChannelListQuery?) throws {
        try env.client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    name: name,
                    members: [.dummy(user: .dummy(userId: self.currentUserId))]
                ),
                query: query,
                cache: nil
            )
        }
    }

    private func waitForChannels(until condition: @escaping ([ChatChannel]) -> Bool) async throws {
        let deadline = Date().addingTimeInterval(defaultTimeout)
        while Date() < deadline {
            if await MainActor.run(body: { condition(channelSearch.state.channels) }) { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTFail("Timed out waiting for the channels to match the expected state")
    }
}

extension ChannelSearch_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var channelListUpdaterSpy: ChannelListUpdater_Spy!

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
                environment: .init(
                    channelListUpdaterBuilder: { [unowned self] database, apiClient in
                        let updater = ChannelListUpdater_Spy(database: database, apiClient: apiClient)
                        updater.update_completion_result = .success([])
                        channelListUpdaterSpy = updater
                        return updater
                    }
                )
            )
            _ = search.state
            return search
        }
    }
}
