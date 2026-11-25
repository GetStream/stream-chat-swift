//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UnifiedSearchResults_Tests: XCTestCase {
    let query = UnifiedSearchQuery(text: "ali")

    // MARK: - nextPageCursors

    func test_nextPageCursors_returnsRequestedSectionsWithMoreResults() {
        let results = UnifiedSearchResults(
            query: query,
            channels: UnifiedSearchSection(next: "c1"),
            messages: UnifiedSearchSection(next: "m1"),
            users: UnifiedSearchSection(next: nil)
        )

        XCTAssertEqual([.channels: "c1", .messages: "m1"], results.nextPageCursors(for: [.channels, .messages, .users]))
        XCTAssertEqual([.messages: "m1"], results.nextPageCursors(for: [.messages, .users]))
        XCTAssertEqual([:], results.nextPageCursors(for: [.users]))
    }

    // MARK: - applyNextPage

    func test_applyNextPage_appendsNewItemsSkipsLoadedOnesAndAdvancesCursor() {
        let general = ChatChannel.mock(cid: .unique)
        let random = ChatChannel.mock(cid: .unique)
        var results = UnifiedSearchResults(query: query, channels: UnifiedSearchSection(items: [general], next: "c1"))
        let page = UnifiedSearchResults(channels: UnifiedSearchSection(items: [general, random], next: "c2"))

        let didChange = results.applyNextPage(page, loadedFor: query, with: [.channels: "c1"])

        XCTAssertTrue(didChange)
        XCTAssertEqual([general.cid, random.cid], results.channels.items.map(\.cid))
        XCTAssertEqual("c2", results.channels.next)
    }

    func test_applyNextPage_whenLastPageIsLoaded_thenSectionHasLoadedAll() {
        var results = UnifiedSearchResults(query: query, users: UnifiedSearchSection(items: [.mock(id: "alice")], next: "u1"))
        let page = UnifiedSearchResults(users: UnifiedSearchSection(items: [.mock(id: "alina")]))

        _ = results.applyNextPage(page, loadedFor: query, with: [.users: "u1"])

        XCTAssertEqual(["alice", "alina"], results.users.items.map(\.id))
        XCTAssertTrue(results.users.hasLoadedAll)
    }

    func test_applyNextPage_whenResultsBelongToAnotherQuery_thenNothingChanges() {
        var results = UnifiedSearchResults(query: query, users: UnifiedSearchSection(items: [.mock(id: "alice")], next: "u1"))
        let page = UnifiedSearchResults(users: UnifiedSearchSection(items: [.mock(id: "alina")]))

        let didChange = results.applyNextPage(page, loadedFor: UnifiedSearchQuery(text: "bob"), with: [.users: "u1"])

        XCTAssertFalse(didChange)
        XCTAssertEqual(["alice"], results.users.items.map(\.id))
        XCTAssertEqual("u1", results.users.next)
    }

    func test_applyNextPage_whenSectionMovedPastCursor_thenOnlyThatSectionIsSkipped() {
        var results = UnifiedSearchResults(
            query: query,
            messages: UnifiedSearchSection(items: [makeHit(id: "m-1")], next: "m2"),
            users: UnifiedSearchSection(items: [.mock(id: "alice")], next: "u1")
        )
        let page = UnifiedSearchResults(
            messages: UnifiedSearchSection(items: [makeHit(id: "m-2")], next: "m2"),
            users: UnifiedSearchSection(items: [.mock(id: "alina")])
        )

        let didChange = results.applyNextPage(page, loadedFor: query, with: [.messages: "m1", .users: "u1"])

        XCTAssertTrue(didChange)
        XCTAssertEqual(["m-1"], results.messages.items.map(\.id))
        XCTAssertEqual("m2", results.messages.next)
        XCTAssertEqual(["alice", "alina"], results.users.items.map(\.id))
    }

    func test_applyNextPage_whenSectionIsRestarted_thenItemsAreReplaced() {
        var results = UnifiedSearchResults(query: query, users: UnifiedSearchSection(items: [.mock(id: "alice")], next: "u1"))
        let page = UnifiedSearchResults(users: UnifiedSearchSection(isRestarted: true, items: [.mock(id: "alina")], next: "u-restart"))

        _ = results.applyNextPage(page, loadedFor: query, with: [.users: "u1"])

        XCTAssertEqual(["alina"], results.users.items.map(\.id))
        XCTAssertEqual("u-restart", results.users.next)
    }

    func test_applyNextPage_whenSectionFails_thenItemsAndCursorAreKept() {
        var results = UnifiedSearchResults(query: query, users: UnifiedSearchSection(items: [.mock(id: "alice")], next: "u1"))
        let error = ClientError.UnifiedSearchSectionFailed(code: .backendUnavailable, message: "users search is unavailable")
        let page = UnifiedSearchResults(users: UnifiedSearchSection(error: error))

        let didChange = results.applyNextPage(page, loadedFor: query, with: [.users: "u1"])

        XCTAssertTrue(didChange)
        XCTAssertEqual(["alice"], results.users.items.map(\.id))
        XCTAssertEqual("u1", results.users.next)
        XCTAssertEqual(.backendUnavailable, results.users.error?.code)
    }

    func test_applyNextPage_whenSectionSucceedsAfterFailure_thenErrorIsCleared() {
        let error = ClientError.UnifiedSearchSectionFailed(code: .backendTimeout, message: "users search timed out")
        var results = UnifiedSearchResults(query: query, users: UnifiedSearchSection(error: error, items: [.mock(id: "alice")], next: "u1"))
        let page = UnifiedSearchResults(users: UnifiedSearchSection(items: [.mock(id: "alina")]))

        _ = results.applyNextPage(page, loadedFor: query, with: [.users: "u1"])

        XCTAssertNil(results.users.error)
        XCTAssertEqual(["alice", "alina"], results.users.items.map(\.id))
    }

    // MARK: - Helpers

    private func makeHit(id: MessageId) -> UnifiedSearchMessage {
        UnifiedSearchMessage(channel: nil, message: .mock(id: id))
    }
}
