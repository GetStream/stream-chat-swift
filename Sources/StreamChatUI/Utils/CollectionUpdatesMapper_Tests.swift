//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatUI
import XCTest

final class CollectionUpdatesMapper_Tests: XCTestCase {
    func test_hasConflicts_returnsNil() {
        let mapper = CollectionUpdatesMapper()
        
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

        let indices = mapper.mapToSetsOfIndexPaths(
            changes: changes
        )

        XCTAssertNil(indices)
    }
    
    func test_hasNoConflicts_returnsIndices() {
        let mapper = CollectionUpdatesMapper()
        
        let changes: [ListChange<Int>] = [
            .update(0, index: .init(row: 0, section: 0)),
            .move(
                0,
                fromIndex: .init(row: 1, section: 1),
                toIndex: .init(row: 2, section: 1)
            ),
            .remove(0, index: .init(row: 3, section: 2))
        ]

        let indices = mapper.mapToSetsOfIndexPaths(
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
}
