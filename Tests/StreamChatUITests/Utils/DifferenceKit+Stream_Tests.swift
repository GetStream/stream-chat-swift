//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

final class DifferenceKit_Stream_Tests: XCTestCase {
    fileprivate func makeCollectionView() -> MockCollectionView {
        let window = UIWindow(frame: .zero)
        let collectionView = MockCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        window.addSubview(collectionView)
        return collectionView
    }
    
    fileprivate func makeTableView() -> MockTableView {
        let window = UIWindow(frame: .zero)
        let tableView = MockTableView(frame: .zero)
        window.addSubview(tableView)
        return tableView
    }
    
    func generateUpdatedElementsStagedChangeset(count: Int) -> StagedChangeset<[Int]> {
        let paths = (0..<count).map { ElementPath(element: $0, section: 0) }
        let changeset = Changeset(data: [0], elementUpdated: paths)
        return StagedChangeset(arrayLiteral: changeset)
    }
    
    // MARK: - UICollectionView
    
    func test_collectionViewReconfigureItems_isCalledAlongWithReload() throws {
        let collectionView = makeCollectionView()
        collectionView.reload(
            using: generateUpdatedElementsStagedChangeset(count: 10),
            reconfigure: { $0.item.isMultiple(of: 2) },
            setData: { _ in }
        )
        XCTAssertEqual(collectionView.reconfiguredIndexes.sorted(), [0, 2, 4, 6, 8])
        XCTAssertEqual(collectionView.reloadedIndexes.sorted(), [1, 3, 5, 7, 9])
    }
    
    func test_collectionViewReconfigureItems_isOnlyCalled() throws {
        let collectionView = makeCollectionView()
        collectionView.reload(
            using: generateUpdatedElementsStagedChangeset(count: 5),
            reconfigure: { _ in true },
            setData: { _ in }
        )
        XCTAssertEqual(collectionView.reconfiguredIndexes.sorted(), [0, 1, 2, 3, 4])
        XCTAssertEqual(collectionView.reloadedIndexes.sorted(), [])
    }
    
    func test_collectionViewReloadItems_isOnlyCalled() throws {
        let collectionView = makeCollectionView()
        collectionView.reload(
            using: generateUpdatedElementsStagedChangeset(count: 3),
            reconfigure: { _ in false },
            setData: { _ in }
        )
        XCTAssertEqual(collectionView.reconfiguredIndexes.sorted(), [])
        XCTAssertEqual(collectionView.reloadedIndexes.sorted(), [0, 1, 2])
    }
    
    // MARK: - UITableView
    
    func test_tableViewReconfigureRows_isCalledAlongWithReload() throws {
        let tableView = makeTableView()
        tableView.reload(
            using: generateUpdatedElementsStagedChangeset(count: 10),
            with: .automatic,
            reconfigure: { $0.item.isMultiple(of: 2) },
            setData: { _ in }
        )
        XCTAssertEqual(tableView.reconfiguredIndexes.sorted(), [0, 2, 4, 6, 8])
        XCTAssertEqual(tableView.reloadedIndexes.sorted(), [1, 3, 5, 7, 9])
    }
    
    func test_tableViewReconfigureRows_isOnlyCalled() throws {
        let tableView = makeTableView()
        tableView.reload(
            using: generateUpdatedElementsStagedChangeset(count: 5),
            with: .automatic,
            reconfigure: { _ in true },
            setData: { _ in }
        )
        XCTAssertEqual(tableView.reconfiguredIndexes.sorted(), [0, 1, 2, 3, 4])
        XCTAssertEqual(tableView.reloadedIndexes.sorted(), [])
    }
    
    func test_tableViewReloadRows_isOnlyCalled() throws {
        let tableView = makeTableView()
        tableView.reload(
            using: generateUpdatedElementsStagedChangeset(count: 3),
            with: .automatic,
            reconfigure: { _ in false },
            setData: { _ in }
        )
        XCTAssertEqual(tableView.reconfiguredIndexes.sorted(), [])
        XCTAssertEqual(tableView.reloadedIndexes.sorted(), [0, 1, 2])
    }
}

extension String: Differentiable {}

private extension DifferenceKit_Stream_Tests {
    final class MockCollectionView: UICollectionView {
        private(set) var reconfiguredIndexes = [Int]()
        private(set) var reloadedIndexes = [Int]()
        
        override func reloadItems(at indexPaths: [IndexPath]) {
            reloadedIndexes.append(contentsOf: indexPaths.map(\.item))
        }
        
        override func reconfigureItems(at indexPaths: [IndexPath]) {
            reconfiguredIndexes.append(contentsOf: indexPaths.map(\.item))
        }
    }
    
    final class MockTableView: UITableView {
        private(set) var reconfiguredIndexes = [Int]()
        private(set) var reloadedIndexes = [Int]()
        
        override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
            reloadedIndexes.append(contentsOf: indexPaths.map(\.item))
        }
        
        override func reconfigureRows(at indexPaths: [IndexPath]) {
            reconfiguredIndexes.append(contentsOf: indexPaths.map(\.item))
        }
    }
}
