//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CoreDataLazy_Tests: StressTestCase {
    @CoreDataLazy var value: Int

    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
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
        var context: SpyContext! = SpyContext(persistenStore: database.persistentStoreCoordinator)
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
                        var channel: ChatChannel?
                        self.database.backgroundReadOnlyContext.performAndWait {
                            channel = try? channelDTO.asModel()
                        }

                        // Access some lazy properties. This should be already thread safe.
                        _ = channel?.lastActiveMembers.randomElement()
                        _ = channel?.lastActiveWatchers.randomElement()
                        _ = channel?.latestMessages.randomElement()?.latestReactions.randomElement()

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

    func test_lazyHasEffectWhen_backgroundMappingDisabled() throws {
        let originalIsBackgroundMappingEnabled = StreamRuntimeCheck._isBackgroundMappingEnabled
        StreamRuntimeCheck._isBackgroundMappingEnabled = false

        let context = SpyContext(persistenStore: database.persistentStoreCoordinator)
        let messageDTO = try createMessageDTO(in: context)

        var chatMessage: ChatMessage!
        context.performAndWait {
            do {
                chatMessage = try messageDTO.asModel()
            } catch {
                XCTFail()
                return
            }
        }

        context.performAndWaitCount = 0
        _ = chatMessage.attachmentCounts
        XCTAssertEqual(context.performAndWaitCount, 1)
        StreamRuntimeCheck._isBackgroundMappingEnabled = originalIsBackgroundMappingEnabled
    }

    func test_lazyHasNoEffectWhen_backgroundMappingEnabled() throws {
        let originalIsBackgroundMappingEnabled = StreamRuntimeCheck._isBackgroundMappingEnabled
        StreamRuntimeCheck._isBackgroundMappingEnabled = true

        let context = SpyContext(persistenStore: database.persistentStoreCoordinator)
        let messageDTO = try createMessageDTO(in: context)

        var chatMessage: ChatMessage!
        context.performAndWait {
            do {
                chatMessage = try messageDTO.asModel()
            } catch {
                XCTFail()
                return
            }
        }

        context.performAndWaitCount = 0
        _ = chatMessage.attachmentCounts
        XCTAssertEqual(context.performAndWaitCount, 0)
        StreamRuntimeCheck._isBackgroundMappingEnabled = originalIsBackgroundMappingEnabled
    }

    private func createMessageDTO(in context: NSManagedObjectContext) throws -> MessageDTO {
        let id = "test-id"
        try database.createMessage(id: id)

        // Get the DTO for the channel from the background context
        var messageDTO: MessageDTO!
        context.performAndWait {
            messageDTO = context.message(id: id)
        }
        return messageDTO
    }
}

private class SpyContext: NSManagedObjectContext {
    var performAndWaitCount: Int = 0
    @Atomic var isRunningInsidePerformAndWaitBlock: Bool = false

    init(persistenStore: NSPersistentStoreCoordinator) {
        super.init(concurrencyType: .privateQueueConcurrencyType)
        persistentStoreCoordinator = persistenStore
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func performAndWait(_ block: () -> Void) {
        isRunningInsidePerformAndWaitBlock = true
        super.performAndWait(block)
        performAndWaitCount += 1
        isRunningInsidePerformAndWaitBlock = false
    }
}
