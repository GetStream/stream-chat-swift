//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberSearch_Tests: XCTestCase {
    private var channelId: ChannelId!
    private var env: TestEnvironment!
    private var testError: TestError!
    private var memberSearch: MemberSearch!

    @MainActor override func setUpWithError() throws {
        channelId = .unique
        env = TestEnvironment()
        testError = TestError()
        memberSearch = MemberSearch(
            client: env.client,
            environment: env.memberSearchEnvironment,
            // Keep search synchronous in unit tests unless a test opts into debouncing.
            debouncePolicy: .constant(0)
        )
        // Explicitly load the state
        _ = memberSearch.state
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        env = nil
        testError = nil
        memberSearch = nil
        channelId = nil
    }

    // MARK: - Searching Members

    func test_searchText_whenTextMatches_thenResultsAreReturnedAndStateUpdates() async throws {
        let fetchResult = makeMembers(name: "name", count: 5, offset: 0)
        env.memberListUpdaterMock.load_completion_result = .success(fetchResult)
        let result = try await memberSearch.search(text: "name", in: channelId)
        XCTAssertEqual(fetchResult.map(\.id), result.map(\.id))
        await XCTAssertEqual(fetchResult.map(\.id), memberSearch.state.members.map(\.id))

        XCTAssertEqual(1, env.memberListUpdaterMock.load_queries.count)
        try await MainActor.run {
            let query = try XCTUnwrap(memberSearch.state.query)
            XCTAssertEqual(env.memberListUpdaterMock.load_queries.first?.queryHash, query.queryHash)
            XCTAssertEqual(env.memberListUpdaterMock.load_queries.first?.pagination, query.pagination)

            XCTAssertEqual(channelId, query.cid)
            XCTAssertEqual(Filter<MemberListFilterScope>.autocomplete(.name, text: "name"), query.filter)
            XCTAssertEqual(Pagination(pageSize: .channelMembersPageSize), query.pagination)
            XCTAssertEqual([Sorting(key: .name, isAscending: true)], query.sort)
        }
    }

    func test_searchText_whenRequestFails_thenResultsAndStateAreEmpty() async throws {
        env.memberListUpdaterMock.load_completion_result = .failure(testError)
        await XCTAssertAsyncFailure(try await memberSearch.search(text: "name", in: channelId), testError)
    }

    func test_searchOrder_whenSendingMultipleRequests_thenIrrelevantResultsAreIgnored() async throws {
        // Search for "nam"
        let expectation1 = XCTestExpectation()
        env.memberListUpdaterMock.load_query_called = { _ in
            expectation1.fulfill()
        }
        async let result1 = memberSearch.search(text: "nam", in: channelId)

        await fulfillment(of: [expectation1], timeout: defaultTimeout)

        // Search for "name" — cancels the in-flight "nam" search
        let expectation2 = XCTestExpectation()
        env.memberListUpdaterMock.load_query_called = { _ in
            expectation2.fulfill()
        }
        async let result2 = memberSearch.search(text: "name", in: channelId)

        await fulfillment(of: [expectation2], timeout: defaultTimeout)

        XCTAssertEqual(2, env.memberListUpdaterMock.load_completions.count)

        let secondResult = makeMembers(name: "name", count: 5, offset: 0)
        env.memberListUpdaterMock.load_completions[1](.success(secondResult))

        // Completing the cancelled request must not overwrite state.
        let firstResult = makeMembers(name: "nam", count: 10, offset: 0)
        env.memberListUpdaterMock.load_completions[0](.success(firstResult))

        // The superseded search resolves without an error, so typing does not surface one
        // per keystroke. Its own results are dropped in favour of the newer search.
        let supersededResult = try await result1
        XCTAssertEqual(secondResult.map(\.id), supersededResult.map(\.id))

        XCTAssertEqual(5, try await result2.count)
        await XCTAssertEqual(secondResult.map(\.id), memberSearch.state.members.map(\.id))
    }

    // MARK: - Results Pagination

    func test_loadMoreMembers_whenMoreResultsAreAvailable_thenResultsAndStateAreUpdated() async throws {
        let fetchResult1 = makeMembers(name: "name", count: Int.channelMembersPageSize, offset: 0)
        env.memberListUpdaterMock.load_completion_result = .success(fetchResult1)
        try await memberSearch.search(text: "name", in: channelId)

        let fetchResult2 = makeMembers(name: "name", count: 5, offset: Int.channelMembersPageSize)
        env.memberListUpdaterMock.load_completion_result = .success(fetchResult2)
        try await memberSearch.loadMoreMembers(limit: 10)

        let expectedIds = (fetchResult1 + fetchResult2).map(\.id)
        await XCTAssertEqual(expectedIds, memberSearch.state.members.map(\.id))

        XCTAssertEqual(2, env.memberListUpdaterMock.load_queries.count)
        try await MainActor.run {
            let query = try XCTUnwrap(memberSearch.state.query)
            XCTAssertEqual(env.memberListUpdaterMock.load_queries.last?.queryHash, query.queryHash)
            XCTAssertEqual(env.memberListUpdaterMock.load_queries.last?.pagination, query.pagination)

            XCTAssertEqual(channelId, query.cid)
            XCTAssertEqual(Filter<MemberListFilterScope>.autocomplete(.name, text: "name"), query.filter)
            XCTAssertEqual(Pagination(pageSize: 10, offset: .channelMembersPageSize), query.pagination)
            XCTAssertEqual([Sorting(key: .name, isAscending: true)], query.sort)
        }
    }

    // MARK: - Test Data

    private func makeMembers(name: String, count: Int, offset: Int) -> [ChatChannelMember] {
        (0..<count)
            .map { $0 + offset }
            .map { ChatChannelMember.mock(id: "\($0)", name: "\(name)_\(String(format: "%03d", $0))") }
    }
}

extension MemberSearch_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var memberListUpdaterMock: ChannelMemberListUpdater_Mock!

        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
        }

        func cleanUp() {
            client.cleanUp()
            memberListUpdaterMock?.cleanUp()
        }

        lazy var memberSearchEnvironment: MemberSearch.Environment = .init(
            memberListUpdaterBuilder: { [unowned self] in
                self.memberListUpdaterMock = ChannelMemberListUpdater_Mock(
                    database: $0,
                    apiClient: $1
                )
                return memberListUpdaterMock
            }
        )
    }
}
