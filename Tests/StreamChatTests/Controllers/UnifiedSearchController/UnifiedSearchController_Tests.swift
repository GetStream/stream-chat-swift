//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UnifiedSearchController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: UnifiedSearchRepository_Mock!
    var controller: UnifiedSearchController!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repository = client.mockUnifiedSearchRepository
        controller = UnifiedSearchController(
            client: client,
            // Keep search synchronous in unit tests unless a test opts into debouncing.
            debouncePolicy: .constant(0)
        )
    }

    override func tearDown() {
        controller = nil
        repository = nil
        client?.cleanUp()
        client = nil
        super.tearDown()
    }

    // MARK: - search

    func test_searchText_whenRequestSucceeds_thenResultsAreUpdated() {
        let query = UnifiedSearchQuery(text: "ali")
        repository.search_completion_result = .success(makeResults(query, users: ["alice"]))

        let exp = expectation(description: "search completes")
        controller.search(text: "ali") { result in
            XCTAssertEqual(["alice"], result.value?.users.items.map(\.id))
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual([query], repository.search_queries)
        XCTAssertEqual(["alice"], controller.results.users.items.map(\.id))
        XCTAssertEqual(.remoteDataFetched, controller.state)
    }

    @MainActor func test_search_whenRequestSucceeds_thenDelegateIsNotified() {
        let delegate = DelegateMock()
        controller.delegate = delegate
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"]))

        controller.search(text: "ali")

        wait(for: [delegate.expectation], timeout: defaultTimeout)
        XCTAssertEqual(["alice"], delegate.results?.users.items.map(\.id))
    }

    func test_searchText_whenTextIsBlank_thenResultsAreClearedWithoutRequest() {
        repository.search_completion_result = .success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"]))
        let searchExp = expectation(description: "search completes")
        controller.search(text: "ali") { _ in searchExp.fulfill() }
        wait(for: [searchExp], timeout: defaultTimeout)

        let clearExp = expectation(description: "blank search completes")
        controller.search(text: " ") { result in
            XCTAssertEqual(true, result.value?.users.items.isEmpty)
            clearExp.fulfill()
        }

        wait(for: [clearExp], timeout: defaultTimeout)
        XCTAssertEqual(1, repository.search_queries.count)
        XCTAssertTrue(controller.results.users.items.isEmpty)
    }

    func test_search_whenRequestFails_thenErrorIsForwardedAndStateIsFailed() {
        let testError = TestError()
        repository.search_completion_result = .failure(testError)

        let exp = expectation(description: "search completes")
        controller.search(text: "ali") { result in
            XCTAssertEqual(testError, result.error as? TestError)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(controller.results.users.items.isEmpty)
        if case .remoteDataFetchFailed = controller.state {} else {
            XCTFail("Expected remoteDataFetchFailed, got \(controller.state)")
        }
    }

    func test_search_whenOlderResponseArrivesLast_thenItIsIgnored() {
        nonisolated(unsafe) var supersededResults: UnifiedSearchResults?
        let supersededExp = expectation(description: "superseded search completes")
        let latestExp = expectation(description: "latest search completes")
        controller.search(text: "ali") { result in
            supersededResults = result.value
            supersededExp.fulfill()
        }
        controller.search(text: "bob") { _ in latestExp.fulfill() }
        XCTAssertEqual(2, repository.search_completions.count)

        repository.search_completions[1](.success(makeResults(UnifiedSearchQuery(text: "bob"), users: ["bob"])))
        repository.search_completions[0](.success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"])))

        wait(for: [latestExp, supersededExp], timeout: defaultTimeout)
        XCTAssertEqual(["bob"], controller.results.users.items.map(\.id))
        XCTAssertEqual(["bob"], supersededResults?.users.items.map(\.id))
    }

    // MARK: - loadNextResults

    func test_loadNextResults_whenNoSearchCompleted_thenErrorIsReturned() {
        let exp = expectation(description: "load completes")
        controller.loadNextResults { result in
            XCTAssertNotNil(result.error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(repository.search_queries.isEmpty)
    }

    func test_loadNextResults_sendsRequestedSectionsWithMoreResultsAndAppendsPage() {
        let query = UnifiedSearchQuery(text: "ali", pageSize: 5)
        var results = makeResults(query, users: ["alice"], usersNext: "u1")
        results.messages = UnifiedSearchSection(items: [makeHit(id: "m-1")], next: "m1")
        search(with: results)
        var page = makeResults(query, users: ["alina"])
        page.messages = UnifiedSearchSection(items: [makeHit(id: "m-2")])
        repository.search_completion_result = .success(page)

        let exp = expectation(description: "load completes")
        controller.loadNextResults { result in
            XCTAssertEqual(["alina"], result.value?.users.items.map(\.id))
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(UnifiedSearchQuery(text: "ali", entities: [.messages, .users], pageSize: 5), repository.search_queries.last)
        XCTAssertEqual([.messages: "m1", .users: "u1"], repository.search_cursors.last)
        XCTAssertEqual(["m-1", "m-2"], controller.results.messages.items.map(\.id))
        XCTAssertEqual(["alice", "alina"], controller.results.users.items.map(\.id))
        XCTAssertTrue(controller.results.users.hasLoadedAll)
    }

    func test_loadNextResults_whenNoSectionHasMoreResults_thenNoRequestIsMade() {
        search(with: makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"]))

        let exp = expectation(description: "load completes")
        controller.loadNextResults([.users]) { result in
            XCTAssertEqual(true, result.value?.users.items.isEmpty)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(1, repository.search_queries.count)
    }

    func test_loadNextResults_whenNewerSearchCompletesFirst_thenPageIsDiscarded() {
        search(with: makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"], usersNext: "u1"))
        repository.search_completion_result = nil
        let loadExp = expectation(description: "load completes")
        controller.loadNextResults([.users]) { _ in loadExp.fulfill() }
        search(with: makeResults(UnifiedSearchQuery(text: "bob"), users: ["bob"]))

        repository.search_completions[0](.success(makeResults(UnifiedSearchQuery(text: "ali"), users: ["alina"])))

        wait(for: [loadExp], timeout: defaultTimeout)
        XCTAssertEqual(["bob"], controller.results.users.items.map(\.id))
    }

    // MARK: - clearResults

    @MainActor func test_clearResults_clearsResultsAndNotifiesDelegate() {
        search(with: makeResults(UnifiedSearchQuery(text: "ali"), users: ["alice"]))
        let delegate = DelegateMock()
        controller.delegate = delegate

        controller.clearResults()

        wait(for: [delegate.expectation], timeout: defaultTimeout)
        XCTAssertTrue(controller.results.users.items.isEmpty)
        XCTAssertEqual(true, delegate.results?.users.items.isEmpty)
    }

    // MARK: - Factory

    func test_unifiedSearchController_factoryReturnsController() {
        XCTAssertNotNil(client.unifiedSearchController())
    }

    // MARK: - Helpers

    private final class DelegateMock: UnifiedSearchControllerDelegate {
        var results: UnifiedSearchResults?
        let expectation = XCTestExpectation(description: "Did Change Results")

        func controller(_ controller: UnifiedSearchController, didChangeResults results: UnifiedSearchResults) {
            self.results = results
            expectation.fulfill()
        }
    }

    private func search(with results: UnifiedSearchResults) {
        repository.search_completion_result = .success(results)
        let exp = expectation(description: "search completes")
        controller.search(query: results.query ?? UnifiedSearchQuery(text: "ali")) { _ in exp.fulfill() }
        wait(for: [exp], timeout: defaultTimeout)
    }

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
}
