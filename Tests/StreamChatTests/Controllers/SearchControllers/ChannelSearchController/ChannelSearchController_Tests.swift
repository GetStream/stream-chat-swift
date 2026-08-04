//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelSearchController_Tests: XCTestCase {
    private var client: ChatClient_Mock!
    private var env: TestEnvironment!
    private var controller: ChatChannelSearchController!
    private var memberId: UserId!

    private var updater: ChannelListUpdater_Spy? { env.channelListUpdater }

    override func setUp() {
        super.setUp()
        memberId = .unique
        client = .mock()
        client.currentUserId_mock = memberId
        env = TestEnvironment()
        // Keep search synchronous unless a test opts into debouncing.
        controller = makeController(debouncePolicy: .constant(0))
    }

    override func tearDown() {
        env.channelListUpdater?.cleanUp()
        client.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }
        super.tearDown()
    }

    private func makeController(debouncePolicy: SearchDebouncePolicy) -> ChatChannelSearchController {
        ChatChannelSearchController(
            client: client,
            environment: env.environment,
            debouncePolicy: debouncePolicy
        )
    }

    // MARK: - Query

    func test_search_queriesForTheSearchTextWithoutWatching() {
        controller.search(text: "general")

        let query = updater?.update_queries.first
        XCTAssertTrue(query?.filter.description.contains("general") == true)
        XCTAssertTrue(query?.options.isEmpty == true)
    }

    func test_search_reusesTheSameQueryIdentityAcrossSearches() {
        controller.search(text: "gen")
        controller.search(text: "general")

        let hashes = updater?.update_queries.map(\.queryHash)
        XCTAssertEqual(hashes?.count, 2)
        XCTAssertEqual(hashes?.first, controller.explicitQueryHash)
        XCTAssertEqual(hashes?.last, controller.explicitQueryHash)
    }

    func test_search_whenTextIsEmpty_clearsResults() {
        controller.search(text: "general")
        XCTAssertNotNil(controller.lastQuery)

        controller.search(text: "")

        XCTAssertNil(controller.lastQuery)
        XCTAssertEqual(updater?.update_queries.count, 1)
    }

    func test_search_whenBelowMinimumCharacterCount_doesNotQuery() {
        controller = makeController(debouncePolicy: .constant(0, minimumCharacterCount: 3))

        let expectation = expectation(description: "Completion called when search is skipped")
        controller.search(text: "ab") { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertTrue(updater?.update_queries.isEmpty ?? true)
    }

    func test_search_whenQueryHasNoSearchText_runsWithoutDebouncing() {
        controller = makeController(debouncePolicy: .constant(0.15))

        controller.search(query: ChannelListQuery(filter: .in(.members, values: [memberId])))

        XCTAssertEqual(updater?.update_queries.count, 1)
    }

    // MARK: - Debouncing

    func test_search_respectsDebouncePolicy() {
        controller = makeController(debouncePolicy: .constant(0.15))
        controller.search(text: "general")

        XCTAssertTrue(updater?.update_queries.isEmpty ?? true)

        let expectation = expectation(description: "Debounced channel search fires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.updater?.update_queries.count, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_clearResults_cancelsPendingDebouncedSearch() {
        controller = makeController(debouncePolicy: .constant(0.15))
        controller.search(text: "general")
        controller.clearResults()

        let expectation = expectation(description: "Cancelled search does not reach the updater")
        expectation.isInverted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if self.updater?.update_queries.isEmpty == false {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 0.4)
    }

    func test_channelSearchController_usesTheDefaultDebouncePolicy() {
        controller = client.channelSearchController()

        // The default policy debounces 3 character queries by 300ms, so nothing happens yet.
        controller.search(text: "abc")
        XCTAssertNil(controller.lastQuery)

        let expectation = expectation(description: "Default debounced search fires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            XCTAssertNotNil(self.controller.lastQuery)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    // MARK: - Results

    func test_channels_reportsChannelsLinkedToTheSearchQuery() throws {
        controller.search(text: "general")
        let searchQuery = try XCTUnwrap(controller.lastQuery)

        let cid = ChannelId.unique
        try writeChannel(cid: cid, name: "general", query: searchQuery)

        try waitForChannels(equalTo: [cid])
    }

    @MainActor func test_delegate_isNotifiedWhenALinkedChannelChanges() throws {
        controller.search(text: "general")
        let searchQuery = try XCTUnwrap(controller.lastQuery)

        let cid = ChannelId.unique
        try writeChannel(cid: cid, name: "general", query: searchQuery)
        try waitForChannels(equalTo: [cid])

        let delegate = ChannelSearchController_Delegate()
        controller.delegate = delegate
        let change = expectation(description: "Delegate reports the channel change")
        change.assertForOverFulfill = false
        delegate.didChangeChannels = {
            guard self.controller.channels.first?.name == "general channel" else { return }
            change.fulfill()
        }

        // The channel is updated without being re-linked to the query.
        try writeChannel(cid: cid, name: "general channel", query: nil)

        wait(for: [change], timeout: defaultTimeout)
    }

    func test_search_alwaysQueriesTheFirstPage() {
        // An initial fetch is what makes the updater replace the previously linked results.
        controller.search(text: "gen")
        controller.search(text: "general")

        let paginations = updater?.update_queries.map(\.pagination)
        XCTAssertEqual(paginations?.count, 2)
        XCTAssertEqual(paginations?.filter { $0.offset == 0 && $0.cursor == nil }.count, 2)
    }

    func test_clearResults_unlinksTheResults() throws {
        controller.search(text: "general")
        let searchQuery = try XCTUnwrap(controller.lastQuery)
        try writeChannel(cid: .unique, name: "general", query: searchQuery)
        try waitForChannels { !$0.isEmpty }

        let expectation = expectation(description: "Results are cleared")
        controller.clearResults { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)

        try waitForChannels(equalTo: [])
    }

    // MARK: - Pagination

    func test_loadNextChannels_withoutSearch_returnsError() {
        let expectation = expectation(description: "Error for missing search")
        controller.loadNextChannels { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_loadNextChannels_paginatesTheCurrentSearchQuery() throws {
        controller.search(text: "general")
        let searchQuery = try XCTUnwrap(controller.lastQuery)
        try writeChannel(cid: .unique, name: "general", query: searchQuery)
        try waitForChannels { $0.count == 1 }

        controller.loadNextChannels(limit: 10)

        let paginationQuery = updater?.update_queries.last
        XCTAssertEqual(paginationQuery?.queryHash, controller.explicitQueryHash)
        XCTAssertEqual(paginationQuery?.pagination.pageSize, 10)
        XCTAssertEqual(paginationQuery?.pagination.offset, 1)
    }

    // MARK: - Helpers

    private func writeChannel(cid: ChannelId, name: String, query: ChannelListQuery?) throws {
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    name: name,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: query,
                cache: nil
            )
        }
    }

    private func waitForChannels(equalTo cids: [ChannelId]) throws {
        try waitForChannels { $0.map(\.cid) == cids }
    }

    private func waitForChannels(until condition: @escaping ([ChatChannel]) -> Bool) throws {
        let expectation = expectation(description: "Channels match the expected state")
        expectation.assertForOverFulfill = false
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(20))
        timer.setEventHandler {
            if condition(self.controller.channels) {
                expectation.fulfill()
            }
        }
        timer.resume()
        defer { timer.cancel() }
        wait(for: [expectation], timeout: defaultTimeout)
    }
}

@MainActor private final class ChannelSearchController_Delegate: ChatChannelSearchControllerDelegate {
    var didChangeChannels: (() -> Void)?

    func controller(
        _ controller: ChatChannelSearchController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        didChangeChannels?()
    }
}

private class TestEnvironment {
    @Atomic var channelListUpdater: ChannelListUpdater_Spy?

    lazy var environment: ChatChannelSearchController.Environment =
        .init(
            channelListUpdaterBuilder: { [unowned self] in
                self.channelListUpdater = ChannelListUpdater_Spy(
                    database: $0,
                    apiClient: $1
                )
                return self.channelListUpdater!
            }
        )
}
