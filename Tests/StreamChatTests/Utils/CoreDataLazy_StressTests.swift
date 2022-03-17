//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CoreDataLazy_Tests: StressTestCase {
    @CoreDataLazy var value: Int
    
    var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
    }
    
    override func tearDown() {
        database = nil
        super.tearDown()
    }
    
    func test_theValueIsCached() {
        var counter = 0
        
        let result = Int.random(in: Int.min...Int.max)
        
        // Every time the lazy closure is accessed it increases the counter
        $value = ({
            counter += 1
            return result
        }, nil)
        
        // Assert the value hasn't been evaluated yet
        XCTAssertEqual(counter, 0)
        
        // Evaluate the value and check the result is correct a couple of times
        XCTAssertEqual(value, result)
        XCTAssertEqual(value, result)
        XCTAssertEqual(value, result)
        XCTAssertEqual(value, result)
        
        // Assert the value was evaluated just once
        XCTAssertEqual(counter, 1)
    }
    
    func test_theClosureIsEvaluatedOnTheContextQueue() {
        class SpyContext: NSManagedObjectContext {
            @Atomic var isRunningInsidePerformAndWaitBlock: Bool = false
            override func performAndWait(_ block: () -> Void) {
                isRunningInsidePerformAndWaitBlock = true
                block()
                isRunningInsidePerformAndWaitBlock = false
            }
        }
        
        var context: SpyContext! = SpyContext(concurrencyType: .privateQueueConcurrencyType)
        let result = Int.random(in: Int.min...Int.max)
        
        // Every time the lazy closure is accessed it increases the counter
        $value = ({
            XCTAssertTrue(context.isRunningInsidePerformAndWaitBlock)
            return result
        }, context)
        
        // Evaluate the value
        XCTAssertEqual(value, result)
        AssertAsync.canBeReleased(&context)
    }
    
    func test_behavesCorrectly_whenAccessedFromMultipleThreads() throws {
        // This has to be tested on some more complex object, so we use `ChannelDTO`.
        
        // Create a channel in the DB
        let cid = ChannelId.unique
        try database.createChannel(cid: cid, withMessages: true)
        
        // Get the DTO for the channel from the background context
        var channelDTO: ChannelDTO!
        
        database.backgroundReadOnlyContext.performAndWait {
            channelDTO = database.backgroundReadOnlyContext.channel(cid: cid)!
        }
        
        // Read and write randomly to the DB and test it doesn't crash
        let group = DispatchGroup()
        for _ in 0...100 {
            group.enter()
            DispatchQueue.random.async {
                self.database.write { session in
                    // This completely replaces the existing channel data with new data
                    try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
                    group.enter()
                
                    DispatchQueue.random.async {
                        // Serialize the DTO into a new model. This needs to be done on the valid queue for the DTO.
                        var channel: ChatChannel!
                        self.database.backgroundReadOnlyContext.performAndWait {
                            channel = channelDTO.asModel()
                        }
                        
                        // Access some lazy properties. This should be already thread safe.
                        _ = channel.lastActiveMembers.randomElement()
                        _ = channel.lastActiveWatchers.randomElement()
                        _ = channel.latestMessages.randomElement()?.latestReactions.randomElement()
                        
                        group.leave()
                    }

                } completion: { error in
                    XCTAssertNil(error)
                    group.leave()
                }
            }
        }
        group.wait()
    }
}
