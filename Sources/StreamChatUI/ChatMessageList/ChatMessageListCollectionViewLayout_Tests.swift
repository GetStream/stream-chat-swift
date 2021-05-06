//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import XCTest

final class ChatMessageListCollectionViewLayout_Tests: XCTestCase {
    private final class TestUpdateItem: UICollectionViewUpdateItem {
        let _indexPathAfterUpdate: IndexPath?
        override var indexPathAfterUpdate: IndexPath? { _indexPathAfterUpdate }
        
        let _indexPathBeforeUpdate: IndexPath?
        override var indexPathBeforeUpdate: IndexPath? { _indexPathBeforeUpdate }
        
        let _updateAction: UICollectionViewUpdateItem.Action
        override var updateAction: UICollectionViewUpdateItem.Action { _updateAction }
        
        init(
            indexPathBeforeUpdate: IndexPath?,
            indexPathAfterUpdate: IndexPath?,
            updateAction: UICollectionViewUpdateItem.Action
        ) {
            _indexPathBeforeUpdate = indexPathBeforeUpdate
            _indexPathAfterUpdate = indexPathAfterUpdate
            _updateAction = updateAction
        }
        
        convenience init(deleteIndex: Int) {
            self.init(
                indexPathBeforeUpdate: IndexPath(item: deleteIndex, section: 0),
                indexPathAfterUpdate: nil,
                updateAction: .delete
            )
        }
        
        convenience init(insertIndex: Int) {
            self.init(
                indexPathBeforeUpdate: nil,
                indexPathAfterUpdate: IndexPath(item: insertIndex, section: 0),
                updateAction: .insert
            )
        }
    }
    
    private typealias LayoutItem = ChatMessageListCollectionViewLayout.LayoutItem
    
    private var subject: ChatMessageListCollectionViewLayout!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        subject = .init()
    }
    
    override func tearDown() {
        super.tearDown()
        subject = nil
    }
    
    // MARK: - Tests
    
    func test_messageListLayout_handlesDeletions() {
        let indices = 0..<20
        
        subject.currentItems = indices.map { LayoutItem(offset: CGFloat($0 * 200), height: 200) }
        
        let updateItems = indices.map(TestUpdateItem.init(deleteIndex:))
        
        subject._prepare(forCollectionViewUpdates: updateItems)
        
        XCTAssertTrue(subject.currentItems.isEmpty)
    }
    
    func test_messageListLayout_handlesInsertions() throws {
        subject._prepare(forCollectionViewUpdates: [TestUpdateItem(insertIndex: 0)])
        
        // As `UUID` in `LayoutItem.id` is "random" adding `Equatable` conformance and direct comparison
        // wouldn't make sense as we have one "random" property
        XCTAssertEqual(subject.currentItems.count, 1)
        
        let firstItem = try XCTUnwrap(subject.currentItems.first)
        
        XCTAssertEqual(firstItem.offset, 0)
        XCTAssertEqual(firstItem.height, subject.estimatedItemHeight)
    }
    
    func test_messageListLayout_hasCorrectStickyHeaderAttributes() {
        subject.hasStickyTopItem = true
        subject.spacing = 10
        subject.currentItems = [LayoutItem(offset: 0, height: 100)]
        
        let receivedAttrs = subject.stickyHeaderDecorationAttributes
        
        XCTAssertEqual(1, receivedAttrs?.zIndex)
        XCTAssertEqual(IndexPath(item: 0, section: 0), receivedAttrs?.indexPath)
        XCTAssertEqual(CGRect(x: 0, y: 0, width: 0, height: 110), receivedAttrs?.frame)
        XCTAssertEqual(subject.stickyHeaderBackground, receivedAttrs?.representedElementKind)
        XCTAssertEqual(.decorationView, receivedAttrs?.representedElementCategory)
    }
    
    func test_messageListLayout_hasNoStickyHeaderAttributes_withoutStickyHeader() {
        subject.hasStickyTopItem = false
        subject.currentItems = [LayoutItem(offset: 0, height: 100)]
        
        XCTAssertNil(subject.stickyHeaderDecorationAttributes)
    }
    
    func test_messageListLayout_hasNoStickyHeaderAttributes_whenEmpty() {
        subject.hasStickyTopItem = true
        subject.currentItems = []
        
        XCTAssertNil(subject.stickyHeaderDecorationAttributes)
    }
}
