//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import XCTest

class TableViewListChangeUpdater_Tests: XCTestCase {
    var sut: TableViewListChangeUpdater!
    var tableViewSpy: TableView_Spy!

    struct MockItem {}

    override func setUpWithError() throws {
        tableViewSpy = TableView_Spy()
        sut = TableViewListChangeUpdater(tableView: tableViewSpy)
    }

    override func tearDownWithError() throws {
        sut = nil
        tableViewSpy = nil
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
        tableViewSpy.onInsertRowsCall = { _ in
            expInsert.fulfill()
        }
        let expUpdate = expectation(description: "should call update items")
        tableViewSpy.onReloadRowsCall = { _ in
            expUpdate.fulfill()
        }
        let expDelete = expectation(description: "should call delete items")
        tableViewSpy.onDeleteRowsCall = { _ in
            expDelete.fulfill()
        }
        let expMove = expectation(description: "should call move items")
        tableViewSpy.onMoveRowCall = { _, _ in
            expMove.fulfill()
        }

        // WHEN
        let changes = [move, insertion, deletion, update]
        sut.performUpdate(with: changes)
        tableViewSpy.simulatePerformBatchUpdates?()

        // THEN
        wait(for: [expDelete, expInsert, expUpdate, expMove], timeout: 0.5, enforceOrder: true)
    }

    func test_performUpdate_whenThereAreConflicts_thenReloadData() throws {
        // GIVEN
        let insertion = ListChange<MockItem>.insert(MockItem(), index: IndexPath(row: 0, section: 0))
        let update = ListChange<MockItem>.update(MockItem(), index: IndexPath(row: 0, section: 0))

        // WHEN
        sut.performUpdate(with: [insertion, update])
        tableViewSpy.simulatePerformBatchUpdates?()

        // THEN
        XCTAssertEqual(tableViewSpy.reloadDataCallCount, 1)
        XCTAssertEqual(tableViewSpy.performBatchUpdatesCallCount, 0)
    }

    func test_performUpdate_whenNoConflicts_thenCallPerformBatchUpdates() throws {
        // GIVEN
        let insertion = ListChange<MockItem>.insert(MockItem(), index: IndexPath(row: 0, section: 0))
        let update = ListChange<MockItem>.update(MockItem(), index: IndexPath(row: 1, section: 0))

        // WHEN
        sut.performUpdate(with: [insertion, update])
        tableViewSpy.simulatePerformBatchUpdates?()

        // THEN
        XCTAssertEqual(tableViewSpy.reloadDataCallCount, 0)
        XCTAssertEqual(tableViewSpy.performBatchUpdatesCallCount, 1)
    }

    class TableView_Spy: UITableView {
        init() {
            super.init(frame: .zero, style: .plain)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var onReloadRowsCall: (([IndexPath]) -> Void)?
        var onInsertRowsCall: (([IndexPath]) -> Void)?
        var onDeleteRowsCall: (([IndexPath]) -> Void)?
        var onMoveRowCall: ((IndexPath, IndexPath) -> Void)?

        var performBatchUpdatesCallCount = 0
        var simulatePerformBatchUpdates: (() -> Void)?
        var simulatePerformBatchUpdatesCompletion: ((Bool) -> Void)?

        var reloadDataCallCount = 0

        override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
            onReloadRowsCall?(indexPaths)
        }

        override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
            onInsertRowsCall?(indexPaths)
        }

        override func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
            onDeleteRowsCall?(indexPaths)
        }

        override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
            onMoveRowCall?(indexPath, newIndexPath)
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
