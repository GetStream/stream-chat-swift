//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

        let path = \MemberPayload.user?.id

        XCTAssertEqual(
            ListChange.insert(insertedItem, index: insertedAt).fieldChange(path),
            .insert(insertedItem.user!.id, index: insertedAt)
        )
        XCTAssertEqual(
            ListChange.update(updatedItem, index: updatedAt).fieldChange(path),
            .update(updatedItem.user!.id, index: updatedAt)
        )
        XCTAssertEqual(
            ListChange.remove(removedItem, index: removedAt).fieldChange(path),
            .remove(removedItem.user!.id, index: removedAt)
        )
        XCTAssertEqual(
            ListChange.move(movedItem, fromIndex: movedFrom, toIndex: movedTo).fieldChange(path),
            .move(movedItem.user!.id, fromIndex: movedFrom, toIndex: movedTo)
        )
    }

    func test_isMove() {
        let mockIndexPath = IndexPath(item: 0, section: 0)
        let listChange = ListChange.move("test", fromIndex: mockIndexPath, toIndex: mockIndexPath)
        XCTAssertTrue(listChange.isMove)

        let otherChanges: [ListChange<String>] = [
            ListChange.insert("test", index: mockIndexPath),
            ListChange.update("test", index: mockIndexPath),
            ListChange.remove("test", index: mockIndexPath)
        ]

        otherChanges.forEach {
            XCTAssertFalse($0.isMove)
        }
    }

    func test_isInsertion() {
        let mockIndexPath = IndexPath(item: 0, section: 0)
        let listChange = ListChange.insert("test", index: mockIndexPath)
        XCTAssertTrue(listChange.isInsertion)

        let otherChanges: [ListChange<String>] = [
            ListChange.move("", fromIndex: mockIndexPath, toIndex: mockIndexPath),
            ListChange.update("test", index: mockIndexPath),
            ListChange.remove("test", index: mockIndexPath)
        ]

        otherChanges.forEach {
            XCTAssertFalse($0.isInsertion)
        }
    }

    func test_isRemove() {
        let mockIndexPath = IndexPath(item: 0, section: 0)
        let listChange = ListChange.remove("test", index: mockIndexPath)
        XCTAssertTrue(listChange.isRemove)

        let otherChanges: [ListChange<String>] = [
            ListChange.move("", fromIndex: mockIndexPath, toIndex: mockIndexPath),
            ListChange.update("test", index: mockIndexPath),
            ListChange.insert("test", index: mockIndexPath)
        ]

        otherChanges.forEach {
            XCTAssertFalse($0.isRemove)
        }
    }

    func test_isUpdate() {
        let mockIndexPath = IndexPath(item: 0, section: 0)
        let listChange = ListChange.update("test", index: mockIndexPath)
        XCTAssertTrue(listChange.isUpdate)

        let otherChanges: [ListChange<String>] = [
            ListChange.move("", fromIndex: mockIndexPath, toIndex: mockIndexPath),
            ListChange.remove("test", index: mockIndexPath),
            ListChange.insert("test", index: mockIndexPath)
        ]

        otherChanges.forEach {
            XCTAssertFalse($0.isUpdate)
        }
    }

    func test_indexPath() {
        let move = ListChange.move(
            "",
            fromIndex: IndexPath(item: 3, section: 3),
            toIndex: IndexPath(item: 4, section: 4)
        )
        let remove = ListChange.remove("test", index: IndexPath(item: 2, section: 2))
        let insertion = ListChange.insert("test", index: IndexPath(item: 1, section: 1))
        let update = ListChange.update("test", index: IndexPath(item: 0, section: 0))

        XCTAssertEqual(move.indexPath, IndexPath(item: 4, section: 4))
        XCTAssertEqual(remove.indexPath, IndexPath(item: 2, section: 2))
        XCTAssertEqual(insertion.indexPath, IndexPath(item: 1, section: 1))
        XCTAssertEqual(update.indexPath, IndexPath(item: 0, section: 0))
    }
}
