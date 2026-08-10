//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SearchQueryLength_Tests: XCTestCase {
    func test_fromFilter_withNilFilter_returnsNil() {
        let filter: Filter<UserListFilterScope>? = nil
        XCTAssertNil(SearchQueryLength.fromFilter(filter))
    }

    func test_fromFilter_withAutocomplete_returnsTextLength() {
        let filter = Filter<UserListFilterScope>.autocomplete(.name, text: "abcd")
        XCTAssertEqual(SearchQueryLength.fromFilter(filter), 4)
    }

    func test_fromFilter_withQueryText_returnsTextLength() {
        let filter = Filter<MessageSearchFilterScope>.queryText("hello")
        XCTAssertEqual(SearchQueryLength.fromFilter(filter), 5)
    }

    func test_fromFilter_withAutocompleteNestedInCompoundFilter_returnsTextLength() {
        let filter = Filter<UserListFilterScope>.and([
            .autocomplete(.name, text: "ab"),
            .exists(.id)
        ])
        XCTAssertEqual(SearchQueryLength.fromFilter(filter), 2)
    }

    func test_fromFilter_withMultipleSearchTexts_returnsLongest() {
        let filter = Filter<UserListFilterScope>.or([
            .autocomplete(.name, text: "ab"),
            .autocomplete(.id, text: "abcdef")
        ])
        XCTAssertEqual(SearchQueryLength.fromFilter(filter), 6)
    }

    func test_fromFilter_withoutSearchText_returnsNil() {
        let filter = Filter<UserListFilterScope>.and([
            .equal(.id, to: "a-known-user-id"),
            .exists(.name)
        ])
        // Exact matches are lookups by a known value, not incremental typing, so they must
        // not be debounced.
        XCTAssertNil(SearchQueryLength.fromFilter(filter))
    }
}
