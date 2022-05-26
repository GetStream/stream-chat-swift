//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import XCTest

final class CollectionViewListChangeUpdater_Tests: XCTestCase {
    var sut: CollectionViewListChangeUpdater!
    var collectionViewSpy: CollectionView_Spy!

    struct MockItem {}

    override func setUpWithError() throws {
        collectionViewSpy = CollectionView_Spy()
        sut = CollectionViewListChangeUpdater(collectionView: collectionViewSpy)
    }

    override func tearDownWithError() throws {
        sut = nil
        collectionViewSpy = nil
    }

    func test_performUpdate_thenCallUpdatesInCorrectOrder() throws {
        // GIVEN
        let insertion = ListChange<MockItem>.insert(MockItem(), index: IndexPath(row: 0, section: 0))
        let update = ListChange<MockItem>.update(MockItem(), index: IndexPath(row: 1, section: 0))
        let deletion = ListChange<MockItem>.remove(MockItem(), index: IndexPath(row: 2, section: 0))
        let move = ListChange<MockItem>.move(
            MockItem(), fromIndex: IndexPath(row: 3, section: 0), toIndex: IndexPath(row: 4, section: 0)
        )

        let expInsert = expectation(description: "should call insert items")
        collectionViewSpy.onInsertItemsCall = { _ in
            expInsert.fulfill()
        }
        let expUpdate = expectation(description: "should call update items")
        collectionViewSpy.onReloadItemsCall = { _ in
            expUpdate.fulfill()
        }
        let expDelete = expectation(description: "should call delete items")
        collectionViewSpy.onDeleteItemsCall = { _ in
            expDelete.fulfill()
        }
        let expMove = expectation(description: "should call move items")
        collectionViewSpy.onMoveItemsCall = { _, _ in
            expMove.fulfill()
        }

        // WHEN
        let changes = [move, insertion, deletion, update]
        sut.performUpdate(with: changes)
        collectionViewSpy.simulatePerformBatchUpdates?()

        // THEN
        wait(for: [expDelete, expInsert, expUpdate, expMove], timeout: 0.5, enforceOrder: true)
    }

    func test_performUpdate_whenThereAreConflicts_thenReloadData() throws {
        // GIVEN
        let insertion = ListChange<MockItem>.insert(MockItem(), index: IndexPath(row: 0, section: 0))
        let update = ListChange<MockItem>.update(MockItem(), index: IndexPath(row: 0, section: 0))

        // WHEN
        sut.performUpdate(with: [insertion, update])
        collectionViewSpy.simulatePerformBatchUpdates?()

        // THEN
        XCTAssertEqual(collectionViewSpy.reloadDataCallCount, 1)
        XCTAssertEqual(collectionViewSpy.performBatchUpdatesCallCount, 0)
    }

    func test_performUpdate_whenNoConflicts_thenCallPerformBatchUpdates() throws {
        // GIVEN
        let insertion = ListChange<MockItem>.insert(MockItem(), index: IndexPath(row: 0, section: 0))
        let update = ListChange<MockItem>.update(MockItem(), index: IndexPath(row: 1, section: 0))

        // WHEN
        sut.performUpdate(with: [insertion, update])
        collectionViewSpy.simulatePerformBatchUpdates?()

        // THEN
        XCTAssertEqual(collectionViewSpy.reloadDataCallCount, 0)
        XCTAssertEqual(collectionViewSpy.performBatchUpdatesCallCount, 1)
    }

    class CollectionView_Spy: UICollectionView {
        init() {
            super.init(frame: .zero, collectionViewLayout: .init())
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var onReloadItemsCall: (([IndexPath]) -> Void)?
        var onInsertItemsCall: (([IndexPath]) -> Void)?
        var onDeleteItemsCall: (([IndexPath]) -> Void)?
        var onMoveItemsCall: ((IndexPath, IndexPath) -> Void)?

        var performBatchUpdatesCallCount = 0
        var simulatePerformBatchUpdates: (() -> Void)?
        var simulatePerformBatchUpdatesCompletion: ((Bool) -> Void)?

        var reloadDataCallCount = 0

        override func reloadItems(at indexPaths: [IndexPath]) {
            onReloadItemsCall?(indexPaths)
        }

        override func insertItems(at indexPaths: [IndexPath]) {
            onInsertItemsCall?(indexPaths)
        }

        override func deleteItems(at indexPaths: [IndexPath]) {
            onDeleteItemsCall?(indexPaths)
        }

        override func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
            onMoveItemsCall?(indexPath, newIndexPath)
        }

        override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
            performBatchUpdatesCallCount += 1
            simulatePerformBatchUpdates = updates
            simulatePerformBatchUpdatesCompletion = completion
        }

        override func reloadData() {
            reloadDataCallCount += 1
        }
    }
}
