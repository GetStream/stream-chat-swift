//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelWatcherHandler_Tests: XCTestCase {
    var channelListUpdater: ChannelListUpdater_Spy!
    var handler: ChannelWatcherHandler!
    
    override func setUp() {
        super.setUp()
        
        let database = DatabaseContainer_Spy()
        let apiClient = APIClient_Spy()
        channelListUpdater = ChannelListUpdater_Spy(database: database, apiClient: apiClient)
        channelListUpdater.startWatchingChannels_completion_success = true
        handler = ChannelWatcherHandler(channelListUpdater: channelListUpdater)
    }
    
    override func tearDown() {
        channelListUpdater.cleanUp()
        channelListUpdater = nil
        handler = nil
        
        super.tearDown()
    }
    
    // MARK: - Single Channel Tests
    
    func test_attemptToWatch_singleChannel_callsUpdaterWithChannel() {
        // Given
        let channelId = ChannelId.unique
        let expectation = self.expectation(description: "Watch completed")
        
        // When
        handler.attemptToWatch(channelIds: [channelId]) { _ in
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_callCount, 1)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_cids, [channelId])
    }
    
    func test_attemptToWatch_singleChannel_callsCompletionOnSuccess() {
        // Given
        let channelId = ChannelId.unique
        let expectation = self.expectation(description: "Completion called")
        var receivedError: Error?
        
        // When
        handler.attemptToWatch(channelIds: [channelId]) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertNil(receivedError)
    }
    
    // MARK: - Multiple Channels Tests
    
    func test_attemptToWatch_multipleChannels_callsUpdaterWithAllChannels() {
        // Given
        let channelIds: [ChannelId] = [.unique, .unique, .unique]
        let expectation = self.expectation(description: "Watch completed")
        
        // When
        handler.attemptToWatch(channelIds: channelIds) { _ in
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_callCount, 1)
        XCTAssertEqual(Set(channelListUpdater.startWatchingChannels_cids), Set(channelIds))
    }
    
    // MARK: - Duplicate Prevention Tests
    
    func test_attemptToWatch_whenAlreadyWatching_doesNotMakeDuplicateRequest() {
        // Given
        let channelId = ChannelId.unique
        let expectation1 = self.expectation(description: "First watch completed")
        let expectation2 = self.expectation(description: "Second watch completed")
        
        // When - Make two rapid requests
        handler.attemptToWatch(channelIds: [channelId]) { _ in
            expectation1.fulfill()
        }
        handler.attemptToWatch(channelIds: [channelId]) { _ in
            expectation2.fulfill()
        }
        
        // Then - Only one request should be made
        wait(for: [expectation1, expectation2], timeout: defaultTimeout)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_callCount, 1)
    }
    
    func test_attemptToWatch_whenPartiallyWatching_onlyWatchesNewChannels() {
        // Given
        let channelId1 = ChannelId(type: .messaging, id: "1")
        let channelId2 = ChannelId(type: .messaging, id: "2")
        let channelId3 = ChannelId(type: .messaging, id: "3")

        // First request for channel1 and channel2
        handler.attemptToWatch(channelIds: [channelId1, channelId2], completion: nil)

        let expectation = self.expectation(description: "First watch completed")

        // When - Second request for channel2 and channel3 (channel2 is already being watched)
        handler.attemptToWatch(channelIds: [channelId2, channelId3]) { _ in
            expectation.fulfill()
        }
        
        // Then - Should only watch channel3
        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_callCount, 2)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_cids, [channelId3])
    }
    
    func test_attemptToWatch_whenAllAlreadyWatching_doesNotCallUpdater() {
        // Given
        let channelIds: [ChannelId] = [.unique, .unique]
        
        // First request
        handler.attemptToWatch(channelIds: channelIds, completion: nil)
        
        let expectation = self.expectation(description: "First watch completed")
        
        // When - Second request with same channels
        handler.attemptToWatch(channelIds: channelIds) { _ in
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_callCount, 1)
    }
    
    // MARK: - Active Requests Lifecycle Tests
    
    func test_attemptToWatch_afterRequestCompletes_channelCanBeWatchedAgain() {
        // Given
        let channelId = ChannelId.unique
        let expectation1 = self.expectation(description: "First watch completed")
        
        // First request
        handler.attemptToWatch(channelIds: [channelId]) { _ in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: defaultTimeout)
        
        // Reset spy
        channelListUpdater.startWatchingChannels_callCount = 0
        channelListUpdater.startWatchingChannels_cids = []
        
        let expectation2 = self.expectation(description: "Second watch completed")
        
        // When - Second request after first completes
        handler.attemptToWatch(channelIds: [channelId]) { _ in
            expectation2.fulfill()
        }
        
        // Then - Second request should go through
        wait(for: [expectation2], timeout: defaultTimeout)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_callCount, 1)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_cids, [channelId])
    }
    
    func test_attemptToWatch_multipleChannels_afterSomeComplete_onlyCompletedCanBeWatchedAgain() {
        // Given
        let channelId1 = ChannelId.unique
        let channelId2 = ChannelId.unique
        let expectation1 = self.expectation(description: "First watch completed")
        
        // First request for both channels
        handler.attemptToWatch(channelIds: [channelId1, channelId2]) { _ in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: defaultTimeout)
        
        // Reset spy
        channelListUpdater.startWatchingChannels_callCount = 0
        channelListUpdater.startWatchingChannels_cids = []
        
        let expectation2 = self.expectation(description: "Second watch completed")
        
        // When - Try to watch both again
        handler.attemptToWatch(channelIds: [channelId1, channelId2]) { _ in
            expectation2.fulfill()
        }
        
        // Then - Both should be watched again since first request completed
        wait(for: [expectation2], timeout: defaultTimeout)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_callCount, 1)
        XCTAssertEqual(Set(channelListUpdater.startWatchingChannels_cids), Set([channelId1, channelId2]))
    }
    
    // MARK: - Thread Safety Tests
    
    func test_attemptToWatch_concurrentCallsFromDifferentThreads_preventsDuplicates() {
        // Given - Use thread-safe handler wrapper
        let channelId = ChannelId.unique
        let numberOfThreads = 10
        let expectation = self.expectation(description: "All threads completed")
        expectation.expectedFulfillmentCount = numberOfThreads
        
        // When - Make concurrent attempts from different threads
        for _ in 0..<numberOfThreads {
            DispatchQueue.global().async {
                self.handler.attemptToWatch(channelIds: [channelId]) { _ in
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_callCount, 1)
        XCTAssertEqual(channelListUpdater.startWatchingChannels_cids, [channelId])
    }
}
