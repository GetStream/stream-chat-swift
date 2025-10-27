//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class WatchingChannelsOngoingRequests_Tests: XCTestCase {
    var tracker: WatchingChannelsOngoingRequests!
    
    override func setUp() {
        super.setUp()
        tracker = WatchingChannelsOngoingRequests()
    }
    
    override func tearDown() {
        tracker = nil
        super.tearDown()
    }
    
    // MARK: - isExecutingRequest
    
    func test_isExecutingRequest_whenChannelNotTracked_returnsFalse() {
        // Given
        let cid = ChannelId.unique
        
        // When / Then
        XCTAssertFalse(tracker.isExecutingRequest(for: cid))
    }
    
    func test_isExecutingRequest_whenChannelTracked_returnsTrue() {
        // Given
        let cid = ChannelId.unique
        tracker.add(channelIds: [cid])
        
        // When / Then
        AssertAsync.willBeTrue(tracker.isExecutingRequest(for: cid))
    }
    
    func test_isExecutingRequest_whenChannelRemovedAfterBeingTracked_returnsFalse() {
        // Given
        let cid = ChannelId.unique
        tracker.add(channelIds: [cid])
        
        AssertAsync.willBeTrue(tracker.isExecutingRequest(for: cid))
        
        // When
        tracker.remove(channelIds: [cid])
        
        // Then
        AssertAsync.willBeFalse(tracker.isExecutingRequest(for: cid))
    }
    
    // MARK: - isExecutingRequests
    
    func test_isExecutingRequests_whenNoChannelsTracked_returnsFalse() {
        // Given
        let cids: [ChannelId] = [.unique, .unique, .unique]
        
        // When / Then
        XCTAssertFalse(tracker.isExecutingRequests(for: cids))
    }
    
    func test_isExecutingRequests_whenSomeChannelsTracked_returnsTrue() {
        // Given
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique
        let cid3 = ChannelId.unique
        
        tracker.add(channelIds: [cid1])
        
        // When / Then
        AssertAsync.willBeTrue(tracker.isExecutingRequests(for: [cid1, cid2, cid3]))
    }
    
    func test_isExecutingRequests_whenAllChannelsTracked_returnsTrue() {
        // Given
        let cids: [ChannelId] = [.unique, .unique, .unique]
        tracker.add(channelIds: cids)
        
        // When / Then
        AssertAsync.willBeTrue(tracker.isExecutingRequests(for: cids))
    }
    
    func test_isExecutingRequests_whenNoChannelsFromListTracked_returnsFalse() {
        // Given
        let trackedCids: [ChannelId] = [.unique, .unique]
        let queryCids: [ChannelId] = [.unique, .unique, .unique]
        
        tracker.add(channelIds: trackedCids)
        
        // When / Then
        AssertAsync.willBeFalse(tracker.isExecutingRequests(for: queryCids))
    }
    
    // MARK: - add
    
    func test_add_singleChannel_tracksChannel() {
        // Given
        let cid = ChannelId.unique
        
        // When
        tracker.add(channelIds: [cid])
        
        // Then
        AssertAsync.willBeTrue(tracker.isExecutingRequest(for: cid))
    }
    
    func test_add_multipleChannels_tracksAllChannels() {
        // Given
        let cids: [ChannelId] = [.unique, .unique, .unique]
        
        // When
        tracker.add(channelIds: cids)
        
        // Then
        for cid in cids {
            AssertAsync.willBeTrue(self.tracker.isExecutingRequest(for: cid))
        }
    }
    
    func test_add_duplicateChannel_doesNotCauseDuplicates() {
        // Given
        let cid = ChannelId.unique
        
        // When
        tracker.add(channelIds: [cid])
        tracker.add(channelIds: [cid])
        
        // Then
        AssertAsync.willBeTrue(tracker.isExecutingRequest(for: cid))
        
        // Remove once
        tracker.remove(channelIds: [cid])
        
        // Should be removed completely
        AssertAsync.willBeFalse(tracker.isExecutingRequest(for: cid))
    }
    
    // MARK: - remove
    
    func test_remove_singleChannel_removesChannel() {
        // Given
        let cid = ChannelId.unique
        tracker.add(channelIds: [cid])
        
        AssertAsync.willBeTrue(tracker.isExecutingRequest(for: cid))
        
        // When
        tracker.remove(channelIds: [cid])
        
        // Then
        AssertAsync.willBeFalse(tracker.isExecutingRequest(for: cid))
    }
    
    func test_remove_multipleChannels_removesAllChannels() {
        // Given
        let cids: [ChannelId] = [.unique, .unique, .unique]
        tracker.add(channelIds: cids)
        
        for cid in cids {
            AssertAsync.willBeTrue(self.tracker.isExecutingRequest(for: cid))
        }

        // When
        tracker.remove(channelIds: cids)
        
        // Then
        for cid in cids {
            AssertAsync.willBeFalse(self.tracker.isExecutingRequest(for: cid))
        }
    }
    
    func test_remove_nonExistentChannel_doesNotCrash() {
        // Given
        let cid = ChannelId.unique
        
        // When / Then - Should not crash
        tracker.remove(channelIds: [cid])
        XCTAssertFalse(tracker.isExecutingRequest(for: cid))
    }

    // MARK: - Thread Safety
    
    func test_concurrentAccess_doesNotCrash() {
        // Given
        let cids = (0..<100).map { _ in ChannelId.unique }
        let expectation = self.expectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 300
        
        // When - Perform concurrent operations
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            let cid = cids[index]
            
            // Add
            self.tracker.add(channelIds: [cid])
            expectation.fulfill()
            
            // Check
            _ = self.tracker.isExecutingRequest(for: cid)
            expectation.fulfill()
            
            // Remove
            self.tracker.remove(channelIds: [cid])
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: defaultTimeout)
    }
    
    func test_concurrentAddAndRemove_maintainsConsistency() {
        // Given
        let cid = ChannelId.unique
        let iterations = 1000
        let expectation = self.expectation(description: "Concurrent add/remove complete")
        expectation.expectedFulfillmentCount = iterations * 2
        
        // When - Concurrently add and remove the same channel
        DispatchQueue.global().async {
            for _ in 0..<iterations {
                self.tracker.add(channelIds: [cid])
                expectation.fulfill()
            }
        }
        
        DispatchQueue.global().async {
            for _ in 0..<iterations {
                self.tracker.remove(channelIds: [cid])
                expectation.fulfill()
            }
        }
        
        // Then - Should not crash
        wait(for: [expectation], timeout: defaultTimeout)
    }
}
