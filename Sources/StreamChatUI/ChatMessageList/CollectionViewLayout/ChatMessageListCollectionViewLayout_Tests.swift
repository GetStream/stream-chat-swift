//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import XCTest

@testable import StreamChatUI

final class ChatMessageListCollectionViewLayout_Tests: XCTestCase {
    private var subject: ChatMessageListCollectionViewLayout!
    private var scrollPreservation: TestScrollPreservation!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        scrollPreservation = .init()
        subject = .init(scrollPreservation: scrollPreservation)
    }
    
    // MARK: - Tests
    
    func testPrepareLayoutForCollectionViewUpdatesPreservesScrollOffset() {
        let prepareExpectation = expectation(description: "Check prepare is called")
        scrollPreservation.prepareForUpdatesBody = { _ in prepareExpectation.fulfill() }
        subject.prepare(forCollectionViewUpdates: [])
        wait(for: [prepareExpectation], timeout: 0.5)
    }
    
    func testFinalizeCollectionViewUpdatesPreservesScrollOffset() {
        let finalizeExpectation = expectation(description: "Check finalize is called")
        scrollPreservation.finalizeUpdatesBody = { _, _ in finalizeExpectation.fulfill() }
        subject.finalizeCollectionViewUpdates()
        wait(for: [finalizeExpectation], timeout: 0.5)
    }
    
    func testFinalizeCollectionViewAnimatesScrollToMostRecentMessage() {
        let finalizeExpectation = expectation(description: "Check finalize is called")
        scrollPreservation.finalizeUpdatesBody = { _, animated in
            XCTAssertTrue(animated)
            finalizeExpectation.fulfill()
        }
        subject.appearingItems.insert(subject.mostRecentItem)
        subject.finalizeCollectionViewUpdates()
        wait(for: [finalizeExpectation], timeout: 0.5)
    }
    
    func testFinalizeCollectionViewDoesntAnimateScrollIfMostRecentMessageHaventChanged() {
        let finalizeExpectation = expectation(description: "Check finalize is called")
        scrollPreservation.finalizeUpdatesBody = { _, animated in
            XCTAssertFalse(animated)
            finalizeExpectation.fulfill()
        }
        subject.appearingItems.insert(IndexPath(item: 1, section: 0))
        subject.finalizeCollectionViewUpdates()
        wait(for: [finalizeExpectation], timeout: 0.5)
    }
}

private final class TestScrollPreservation: MessageListScrollPreservation {
    var prepareForUpdatesBody: (ChatMessageListCollectionViewLayout) -> Void = { _ in }
    
    func prepareForUpdates(in layout: ChatMessageListCollectionViewLayout) {
        prepareForUpdatesBody(layout)
    }
    
    var finalizeUpdatesBody: (ChatMessageListCollectionViewLayout, Bool) -> Void = { _, _ in }
    
    func finalizeUpdates(in layout: ChatMessageListCollectionViewLayout, animated: Bool) {
        finalizeUpdatesBody(layout, animated)
    }
}
