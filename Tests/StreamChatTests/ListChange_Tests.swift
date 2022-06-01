//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ListChange_Tests: XCTestCase {
    func test_item() {
        let insertedItem: String = .unique
        let updatedItem: String = .unique
        let removedItem: String = .unique
        let movedItem: String = .unique

        XCTAssertEqual(ListChange.insert(insertedItem, index: [0, 0]).item, insertedItem)
        XCTAssertEqual(ListChange.update(updatedItem, index: [0, 0]).item, updatedItem)
        XCTAssertEqual(ListChange.remove(removedItem, index: [0, 0]).item, removedItem)
        XCTAssertEqual(ListChange.move(movedItem, fromIndex: [0, 0], toIndex: [0, 1]).item, movedItem)
    }

    func test_fieldChange() {
        let insertedItem: MemberPayload = .dummy()
        let insertedAt = IndexPath(item: 1, section: 1)

        let updatedItem: MemberPayload = .dummy()
        let updatedAt = IndexPath(item: 2, section: 3)

        let removedItem: MemberPayload = .dummy()
        let removedAt = IndexPath(item: 3, section: 4)

        let movedItem: MemberPayload = .dummy()
        let movedFrom = IndexPath(item: 5, section: 6)
        let movedTo = IndexPath(item: 7, section: 8)

        let path = \MemberPayload.user.id

        XCTAssertEqual(
            ListChange.insert(insertedItem, index: insertedAt).fieldChange(path),
            .insert(insertedItem.user.id, index: insertedAt)
        )
        XCTAssertEqual(
            ListChange.update(updatedItem, index: updatedAt).fieldChange(path),
            .update(updatedItem.user.id, index: updatedAt)
        )
        XCTAssertEqual(
            ListChange.remove(removedItem, index: removedAt).fieldChange(path),
            .remove(removedItem.user.id, index: removedAt)
        )
        XCTAssertEqual(
            ListChange.move(movedItem, fromIndex: movedFrom, toIndex: movedTo).fieldChange(path),
            .move(movedItem.user.id, fromIndex: movedFrom, toIndex: movedTo)
        )
    }
}
