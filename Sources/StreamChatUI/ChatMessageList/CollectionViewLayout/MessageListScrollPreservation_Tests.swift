//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatUI
import XCTest

final class MessageListMostRecentMessagePreservation_Tests: XCTestCase {
    private var subject: MessageListMostRecentMessagePreservation!
    private var layout: TestLayout!
    private var collectionView: TestCV!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        subject = .init()
        layout = .init()
        collectionView = .init(frame: .zero, collectionViewLayout: layout)
    }
    
    // MARK: - Tests
    
    func testMostRecentMessageIsVisibleWhenItWasOnScreen() {
        collectionView._indexPathsForVisibleItems = [layout.mostRecentItem]
        subject.prepareForUpdates(in: layout)
        XCTAssertTrue(subject.mostRecentMessageWasVisible)
    }
    
    func testMostRecentMessageIsVisibleWhenItWasntOnScreen() {
        collectionView._indexPathsForVisibleItems = [IndexPath(item: 1, section: 0)]
        subject.prepareForUpdates(in: layout)
        XCTAssertFalse(subject.mostRecentMessageWasVisible)
    }
    
    func testFinalizeWhenMostRecentMessageIsVisible() {
        let scrollExpectation = expectation(description: "Subject should scroll to most recent indexPath")
        subject.mostRecentMessageWasVisible = true
        collectionView.scrollToItemBody = { indexPath, position, _ in
            XCTAssertEqual(indexPath, IndexPath(item: 0, section: 0))
            XCTAssertEqual(position, .bottom)
            scrollExpectation.fulfill()
        }
        subject.finalizeUpdates(in: layout, animated: false)
        wait(for: [scrollExpectation], timeout: 0.5)
    }
    
    func testFinalizeWhenMostRecentMessageIsNotVisible() {
        let scrollExpectation = expectation(description: "Subject should not scroll at all")
        scrollExpectation.isInverted = true
        subject.mostRecentMessageWasVisible = false
        collectionView.scrollToItemBody = { _, _, _ in
            scrollExpectation.fulfill()
        }
        subject.finalizeUpdates(in: layout, animated: false)
        wait(for: [scrollExpectation], timeout: 0.5)
    }
    
    func testFinalizePassesAnimatedValue() {
        let scrollExpectation = expectation(description: "Subject should scroll to most recent indexPath")
        let willAnimate = [true, false].randomElement()!
        subject.mostRecentMessageWasVisible = true
        collectionView.scrollToItemBody = { _, _, animated in
            XCTAssertEqual(animated, willAnimate)
            scrollExpectation.fulfill()
        }
        subject.finalizeUpdates(in: layout, animated: willAnimate)
        wait(for: [scrollExpectation], timeout: 0.5)
    }
    
    func testFinalizeResetsMostRecentMessageVisibility() {
        subject.mostRecentMessageWasVisible = true
        subject.finalizeUpdates(in: layout, animated: false)
        XCTAssertFalse(subject.mostRecentMessageWasVisible)
    }
}

private final class TestLayout: ChatMessageListCollectionViewLayout {
}

private final class TestCV: UICollectionView {
    var _indexPathsForVisibleItems = [IndexPath]()
    
    override var indexPathsForVisibleItems: [IndexPath] { _indexPathsForVisibleItems }
    
    var scrollToItemBody: (IndexPath, UICollectionView.ScrollPosition, Bool) -> Void = { _, _, _ in }
    
    override func scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        scrollToItemBody(indexPath, scrollPosition, animated)
    }
}
