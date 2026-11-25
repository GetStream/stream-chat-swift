//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UnifiedSearch_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: UnifiedSearchRepository_Mock!
    var search: UnifiedSearch!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repository = client.mockUnifiedSearchRepository
        search = UnifiedSearch(
            client: client,
            // Keep search synchronous in unit tests unless a test opts into debouncing.
            debouncePolicy: .constant(0)
        )
    }

    override func tearDown() {
        search = nil
        repository = nil
        client?.cleanUp()
        client = nil
        super.tearDown()
    }

    // MARK: - search

    func test_searchText_whenRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        let query = UnifiedSearchQuery(text: "ali")
        repository.search_completion_result = .success(makeResults(query, users: ["alice"], usersNext: "u1"))

        let results = try await search.search(text: " ali ")

        XCTAssertEqual(["alice"], results.users.items.map(\.id))
        XCTAssertEqual([query], repository.search_queries)
        XCTAssertEqual([[:]], repository.search_cursors)
        await MainActor.run {
            XCTAssertEqual(query, search.state.query)
            XCTAssertEqual(["alice"], search.state.results.users.items.map(\.id))
            XCTAssertFalse(search.state.results.users.hasLoadedAll)
        }
    }

    func test_searchText_whenTextIsBlank_thenResultsAreClearedWithoutRequest() async throws {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"]))
        try await search.search(text: "ali")

        let results = try await search.search(text: "  ")

        XCTAssertTrue(results.users.items.isEmpty)
        XCTAssertEqual(1, repository.search_queries.count)
        await MainActor.run {
            XCTAssertNil(search.state.query)
            XCTAssertTrue(search.state.results.users.items.isEmpty)
        }
    }

    func test_search_whenSectionFails_thenSearchSucceedsWithSectionError() async throws {
        let query = UnifiedSearchQuery(text: "ali")
        var results = makeResults(query, users: ["alice"])
        results.messages = UnifiedSearchSection(error: .init(code: .unsupported, message: "messages search is not supported"))
        repository.search_completion_result = .success(results)

        let receivedResults = try await search.search(query: query)

        XCTAssertEqual(.unsupported, receivedResults.messages.error?.code)
        await MainActor.run {
            XCTAssertEqual(.unsupported, search.state.results.messages.error?.code)
            XCTAssertEqual(["alice"], search.state.results.users.items.map(\.id))
        }
    }

    func test_search_whenRequestFails_thenErrorIsThrownAndPreviousResultsAreKept() async throws {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"]))
        try await search.search(text: "ali")
        let testError = TestError()
        repository.search_completion_result = .failure(testError)

        await XCTAssertAsyncFailure(try await search.search(text: "alice"), testError)

        await MainActor.run {
            XCTAssertEqual("alice", search.state.query?.text)
            XCTAssertEqual(["alice"], search.state.results.users.items.map(\.id))
        }
    }

    func test_search_whenSuperseded_thenCurrentResultsAreReturned() async throws {
        let search = UnifiedSearch(client: client, debouncePolicy: .constant(0.05))
        let bobQuery = UnifiedSearchQuery(text: "bob")
        repository.search_completion_result = .success(makeResults(bobQuery, users: ["bob"]))

        async let supersededResults = search.search(text: "ali")
        try await Task.sleep(nanoseconds: 10_000_000)
        let results = try await search.search(query: bobQuery)

        _ = try await supersededResults
        XCTAssertEqual(["bob"], results.users.items.map(\.id))
        XCTAssertEqual([bobQuery], repository.search_queries)
    }

    // MARK: - loadMore

    func test_loadMore_whenNoSearchCompleted_thenErrorIsThrown() async {
        await XCTAssertAsyncFailure(try await search.loadMore(), expectedErrorHandler: { $0 is ClientError })
        XCTAssertTrue(repository.search_queries.isEmpty)
    }

    func test_loadMore_sendsRequestedSectionsWithMoreResultsInOneRequest() async throws {
        let query = UnifiedSearchQuery(text: "ali", pageSize: 5)
        var results = makeResults(query, users: ["alice"], usersNext: "u1")
        results.messages = UnifiedSearchSection(items: [makeHit(id: "m-1")], next: "m1")
        results.channels = UnifiedSearchSection(items: [.mock(cid: .unique)])
        repository.search_completion_result = .success(results)
        try await search.search(query: query)
        var page = makeResults(UnifiedSearchQuery(text: "ali"), users: ["alina"])
        page.messages = UnifiedSearchSection(items: [makeHit(id: "m-2")], next: "m2")
        repository.search_completion_result = .success(page)

        try await search.loadMore()

        XCTAssertEqual(UnifiedSearchQuery(text: "ali", entities: [.messages, .users], pageSize: 5), repository.search_queries.last)
        XCTAssertEqual([.messages: "m1", .users: "u1"], repository.search_cursors.last)
        await MainActor.run {
            XCTAssertEqual(["m-1", "m-2"], search.state.results.messages.items.map(\.id))
            XCTAssertEqual(["alice", "alina"], search.state.results.users.items.map(\.id))
            XCTAssertEqual(1, search.state.results.channels.items.count)
            XCTAssertFalse(search.state.results.messages.hasLoadedAll)
            XCTAssertTrue(search.state.results.users.hasLoadedAll)
        }
    }

    func test_loadMore_singleSection_leavesOtherSectionsUntouched() async throws {
        let query = UnifiedSearchQuery(text: "ali")
        var results = makeResults(query, users: ["alice"], usersNext: "u1")
        results.messages = UnifiedSearchSection(items: [makeHit(id: "m-1")], next: "m1")
        repository.search_completion_result = .success(results)
        try await search.search(query: query)
        repository.search_completion_result = .success(makeResults(query, users: ["alina"]))

        let page = try await search.loadMore([.users])

        XCTAssertEqual(["alina"], page.users.items.map(\.id))
        XCTAssertEqual([.users], repository.search_queries.last?.entities)
        XCTAssertEqual([.users: "u1"], repository.search_cursors.last)
        await MainActor.run {
            XCTAssertEqual(["m-1"], search.state.results.messages.items.map(\.id))
            XCTAssertEqual("m1", search.state.results.messages.next)
        }
    }

    func test_loadMore_whenNoSectionHasMoreResults_thenNoRequestIsMade() async throws {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"]))
        try await search.search(text: "ali")

        let page = try await search.loadMore([.users])

        XCTAssertTrue(page.users.items.isEmpty)
        XCTAssertEqual(1, repository.search_queries.count)
    }

    func test_loadMore_whenRequestFails_thenErrorIsThrownAndStateIsUnchanged() async throws {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"], usersNext: "u1"))
        try await search.search(text: "ali")
        let testError = TestError()
        repository.search_completion_result = .failure(testError)

        await XCTAssertAsyncFailure(try await search.loadMore([.users]), testError)

        await MainActor.run {
            XCTAssertEqual(["alice"], search.state.results.users.items.map(\.id))
            XCTAssertEqual("u1", search.state.results.users.next)
        }
    }

    func test_loadMore_whenNewerSearchCompletesFirst_thenPageIsDiscarded() async throws {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"], usersNext: "u1"))
        try await search.search(text: "ali")
        repository.search_completion_result = nil
        let search: UnifiedSearch = self.search
        let loadMoreTask = Task { try await search.loadMore([.users]) }
        try await waitForPendingRequests(1)
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "bob"), users: ["bob"]))
        try await search.search(text: "bob")

        repository.search_completions[0](.success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alina"])))
        let page = try await loadMoreTask.value

        XCTAssertEqual(["alina"], page.users.items.map(\.id))
        await MainActor.run {
            XCTAssertEqual(["bob"], search.state.results.users.items.map(\.id))
        }
    }

    func test_loadMore_whenResultsAreCleared_thenPageIsDiscarded() async throws {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"], usersNext: "u1"))
        try await search.search(text: "ali")
        repository.search_completion_result = nil
        let search: UnifiedSearch = self.search
        let loadMoreTask = Task { try await search.loadMore([.users]) }
        try await waitForPendingRequests(1)

        await search.clearResults()
        repository.search_completions[0](.success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alina"])))
        _ = try await loadMoreTask.value

        await MainActor.run {
            XCTAssertTrue(search.state.results.users.items.isEmpty)
        }
    }

    func test_loadMore_whileNewerSearchIsInFlight_thenUsesTextOfCurrentResults() async throws {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"], usersNext: "u1"))
        try await search.search(text: "ali")
        repository.search_completion_result = nil
        let search: UnifiedSearch = self.search
        let searchTask = Task { try await search.search(text: "bob") }
        try await waitForPendingRequests(1)
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alina"]))

        try await search.loadMore([.users])

        XCTAssertEqual("ali", repository.search_queries.last?.text)
        await MainActor.run {
            XCTAssertEqual("bob", search.state.query?.text)
            XCTAssertEqual(["alice", "alina"], search.state.results.users.items.map(\.id))
        }
        repository.search_completions[0](.success(makeResults(UnifiedSearchQuery(text: "bob"), users: ["bob"])))
        _ = try await searchTask.value
        await MainActor.run {
            XCTAssertEqual(["bob"], search.state.results.users.items.map(\.id))
        }
    }

    // MARK: - Clearing Results

    func test_clearResults_clearsState() async throws {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"]))
        try await search.search(text: "ali")

        await search.clearResults()

        await MainActor.run {
            XCTAssertNil(search.state.query)
            XCTAssertTrue(search.state.results.users.items.isEmpty)
        }
    }

    // MARK: - Factory

    func test_makeUnifiedSearch_returnsUnifiedSearch() {
        XCTAssertNotNil(client.makeUnifiedSearch())
    }

    // MARK: - Helpers

    private func makeResults(
        _ query: UnifiedSearchQuery,
        users: [UserId],
        usersNext: String? = nil
    ) -> UnifiedSearchResults {
        UnifiedSearchResults(
            query: query,
            users: UnifiedSearchSection(items: users.map { .mock(id: $0) }, next: usersNext)
        )
    }

    private func makeHit(id: MessageId) -> UnifiedSearchMessage {
        UnifiedSearchMessage(channel: nil, message: .mock(id: id))
    }

    private func waitForPendingRequests(_ count: Int) async throws {
        var attempts = 0
        while repository.search_completions.count < count, attempts < 1000 {
            attempts += 1
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        XCTAssertEqual(count, repository.search_completions.count)
    }
}
