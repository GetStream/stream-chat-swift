//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class WatchingChannelsActiveRequests_Tests: XCTestCase {
    var sut: WatchingChannelsActiveRequests!
    
    override func setUp() {
        super.setUp()
        sut = WatchingChannelsActiveRequests()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - isExecutingRequest
    
    func test_isExecutingRequest_whenChannelNotTracked_returnsFalse() {
        // Given
        let cid = ChannelId.unique
        
        // When / Then
        XCTAssertFalse(sut.isExecutingRequest(for: cid))
    }
    
    func test_isExecutingRequest_whenChannelTracked_returnsTrue() {
        // Given
        let cid = ChannelId.unique
        sut.add(channelIds: [cid])
        
        // When / Then
        AssertAsync.willBeTrue(sut.isExecutingRequest(for: cid))
    }
    
    func test_isExecutingRequest_whenChannelRemovedAfterBeingTracked_returnsFalse() {
        // Given
        let cid = ChannelId.unique
        sut.add(channelIds: [cid])
        
        AssertAsync.willBeTrue(sut.isExecutingRequest(for: cid))
        
        // When
        sut.remove(channelIds: [cid])
        
        // Then
        AssertAsync.willBeFalse(sut.isExecutingRequest(for: cid))
    }
    
    // MARK: - isExecutingRequests
    
    func test_isExecutingRequests_whenNoChannelsTracked_returnsFalse() {
        // Given
        let cids: [ChannelId] = [.unique, .unique, .unique]
        
        // When / Then
        XCTAssertFalse(sut.isExecutingRequests(for: cids))
    }
    
    func test_isExecutingRequests_whenSomeChannelsTracked_returnsTrue() {
        // Given
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique
        let cid3 = ChannelId.unique
        
        sut.add(channelIds: [cid1])
        
        // When / Then
        AssertAsync.willBeTrue(sut.isExecutingRequests(for: [cid1, cid2, cid3]))
    }
    
    func test_isExecutingRequests_whenAllChannelsTracked_returnsTrue() {
        // Given
        let cids: [ChannelId] = [.unique, .unique, .unique]
        sut.add(channelIds: cids)
        
        // When / Then
        AssertAsync.willBeTrue(sut.isExecutingRequests(for: cids))
    }
    
    func test_isExecutingRequests_whenNoChannelsFromListTracked_returnsFalse() {
        // Given
        let trackedCids: [ChannelId] = [.unique, .unique]
        let queryCids: [ChannelId] = [.unique, .unique, .unique]
        
        sut.add(channelIds: trackedCids)
        
        // When / Then
        AssertAsync.willBeFalse(sut.isExecutingRequests(for: queryCids))
    }
    
    // MARK: - add
    
    func test_add_singleChannel_tracksChannel() {
        // Given
        let cid = ChannelId.unique
        
        // When
        sut.add(channelIds: [cid])
        
        // Then
        AssertAsync.willBeTrue(sut.isExecutingRequest(for: cid))
    }
    
    func test_add_multipleChannels_tracksAllChannels() {
        // Given
        let cids: [ChannelId] = [.unique, .unique, .unique]
        
        // When
        sut.add(channelIds: cids)
        
        // Then
        for cid in cids {
            AssertAsync.willBeTrue(self.sut.isExecutingRequest(for: cid))
        }
    }
    
    func test_add_duplicateChannel_doesNotCauseDuplicates() {
        // Given
        let cid = ChannelId.unique
        
        // When
        sut.add(channelIds: [cid])
        sut.add(channelIds: [cid])
        
        // Then
        AssertAsync.willBeTrue(sut.isExecutingRequest(for: cid))
        
        // Remove once
        sut.remove(channelIds: [cid])
        
        // Should be removed completely
        AssertAsync.willBeFalse(sut.isExecutingRequest(for: cid))
    }
    
    // MARK: - remove
    
    func test_remove_singleChannel_removesChannel() {
        // Given
        let cid = ChannelId.unique
        sut.add(channelIds: [cid])
        
        AssertAsync.willBeTrue(sut.isExecutingRequest(for: cid))
        
        // When
        sut.remove(channelIds: [cid])
        
        // Then
        AssertAsync.willBeFalse(sut.isExecutingRequest(for: cid))
    }
    
    func test_remove_multipleChannels_removesAllChannels() {
        // Given
        let cids: [ChannelId] = [.unique, .unique, .unique]
        sut.add(channelIds: cids)
        
        for cid in cids {
            AssertAsync.willBeTrue(self.sut.isExecutingRequest(for: cid))
        }

        // When
        sut.remove(channelIds: cids)
        
        // Then
        for cid in cids {
            AssertAsync.willBeFalse(self.sut.isExecutingRequest(for: cid))
        }
    }
    
    func test_remove_nonExistentChannel_doesNotCrash() {
        // Given
        let cid = ChannelId.unique
        
        // When / Then - Should not crash
        sut.remove(channelIds: [cid])
        XCTAssertFalse(sut.isExecutingRequest(for: cid))
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
            self.sut.add(channelIds: [cid])
            expectation.fulfill()
            
            // Check
            _ = self.sut.isExecutingRequest(for: cid)
            expectation.fulfill()
            
            // Remove
            self.sut.remove(channelIds: [cid])
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
                self.sut.add(channelIds: [cid])
                expectation.fulfill()
            }
        }
        
        DispatchQueue.global().async {
            for _ in 0..<iterations {
                self.sut.remove(channelIds: [cid])
                expectation.fulfill()
            }
        }
        
        // Then - Should not crash
        wait(for: [expectation], timeout: defaultTimeout)
    }
}
