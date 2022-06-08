//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatUI
import XCTest

final class ListChangeIndexPathResolver_Tests: XCTestCase {
    func test_resolve_whenHasNoConflicts_returnsIndices() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 0, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 1, section: 1),
                toIndex: .init(row: 2, section: 1)
            ),
            .remove(0, index: .init(row: 3, section: 2))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertEqual(
            indices?.update,
            [
                .init(row: 0, section: 0)
            ]
        )
        XCTAssertEqual(
            indices?.move,
            [
                .init(.init(row: 1, section: 1), .init(row: 2, section: 1))
            ]
        )
        XCTAssertEqual(
            indices?.remove,
            [
                .init(row: 3, section: 2)
            ]
        )
    }

    func test_resolve_whenInsertAndUpdateWithSameIndex_hasNoConflicts_returnsIndices() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 0, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 1, section: 1),
                toIndex: .init(row: 2, section: 1)
            ),
            .remove(0, index: .init(row: 3, section: 2)),
            .insert(0, index: .init(row: 0, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertEqual(
            indices?.update,
            [
                .init(row: 0, section: 0)
            ]
        )
        XCTAssertEqual(
            indices?.move,
            [
                .init(.init(row: 1, section: 1), .init(row: 2, section: 1))
            ]
        )
        XCTAssertEqual(
            indices?.remove,
            [
                .init(row: 3, section: 2)
            ]
        )
        XCTAssertEqual(
            indices?.insert,
            [
                .init(row: 0, section: 0)
            ]
        )
    }

    func test_resolve_whenAllWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()
        
        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 0, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 0, section: 0),
                toIndex: .init(row: 1, section: 0)
            ),
            .remove(0, index: .init(row: 0, section: 0)),
            .insert(0, index: .init(row: 0, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }

    func test_resolve_whenInsertAndRemoveWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 5, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 6, section: 0),
                toIndex: .init(row: 1, section: 0)
            ),
            .remove(0, index: .init(row: 0, section: 0)),
            .insert(0, index: .init(row: 0, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }

    func test_resolve_whenInsertAndMoveFromWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 5, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 0, section: 0),
                toIndex: .init(row: 1, section: 0)
            ),
            .remove(0, index: .init(row: 8, section: 0)),
            .insert(0, index: .init(row: 0, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }

    func test_resolve_whenInsertAndMoveToWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 5, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 1, section: 0),
                toIndex: .init(row: 0, section: 0)
            ),
            .remove(0, index: .init(row: 8, section: 0)),
            .insert(0, index: .init(row: 0, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }

    func test_resolve_whenUpdateAndRemoveWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 0, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 6, section: 0),
                toIndex: .init(row: 1, section: 0)
            ),
            .remove(0, index: .init(row: 0, section: 0)),
            .insert(0, index: .init(row: 5, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }

    func test_resolve_whenUpdateAndMoveFromWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 0, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 0, section: 0),
                toIndex: .init(row: 6, section: 0)
            ),
            .remove(0, index: .init(row: 10, section: 0)),
            .insert(0, index: .init(row: 5, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }

    func test_resolve_whenUpdateAndMoveToWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 0, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 6, section: 0),
                toIndex: .init(row: 0, section: 0)
            ),
            .remove(0, index: .init(row: 10, section: 0)),
            .insert(0, index: .init(row: 5, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }

    func test_resolve_whenRemoveAndMoveToWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 2, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 6, section: 0),
                toIndex: .init(row: 0, section: 0)
            ),
            .remove(0, index: .init(row: 0, section: 0)),
            .insert(0, index: .init(row: 5, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }

    func test_resolve_whenRemoveAndMoveFromWithSameIndex_hasConflicts_returnsNil() {
        let listChangeIndexPathResolver = ListChangeIndexPathResolver()

        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 11, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 0, section: 0),
                toIndex: .init(row: 3, section: 0)
            ),
            .remove(0, index: .init(row: 0, section: 0)),
            .insert(0, index: .init(row: 5, section: 0))
        ]

        let indices = listChangeIndexPathResolver.resolve(
            changes: changes
        )

        XCTAssertNil(indices)
    }
}
