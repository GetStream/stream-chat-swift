//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EntityChange_Tests: XCTestCase {
    func test_item() {
        let createdItem: String = .unique
        let updatedItem: String = .unique
        let removedItem: String = .unique

        XCTAssertEqual(EntityChange.create(createdItem).item, createdItem)
        XCTAssertEqual(EntityChange.update(updatedItem).item, updatedItem)
        XCTAssertEqual(EntityChange.remove(removedItem).item, removedItem)
    }

    func test_fieldChange() {
        let createdItem = TestItem.unique
        let updatedItem = TestItem.unique
        let removedItem = TestItem.unique

        let path = \TestItem.value

        XCTAssertEqual(EntityChange.create(createdItem).fieldChange(path), .create(createdItem.value))
        XCTAssertEqual(EntityChange.update(updatedItem).fieldChange(path), .update(updatedItem.value))
        XCTAssertEqual(EntityChange.remove(removedItem).fieldChange(path), .remove(removedItem.value))
    }

    func test_description() {
        let createdItem: String = .unique
        let updatedItem: String = .unique
        let removedItem: String = .unique

        let pairs: [(EntityChange<String>, String)] = [
            (.create(createdItem), "Create: \(createdItem)"),
            (.update(updatedItem), "Update: \(updatedItem)"),
            (.remove(removedItem), "Remove: \(removedItem)")
        ]

        for (change, description) in pairs {
            XCTAssertEqual(change.description, description)
        }
    }
}
