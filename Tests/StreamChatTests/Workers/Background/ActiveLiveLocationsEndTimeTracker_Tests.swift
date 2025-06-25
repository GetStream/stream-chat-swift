//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ActiveLiveLocationsEndTimeTracker_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var tracker: ActiveLiveLocationsEndTimeTracker!

    override func setUp() {
        super.setUp()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        tracker = ActiveLiveLocationsEndTimeTracker(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&tracker)
        AssertAsync.canBeReleased(&apiClient)
        AssertAsync.canBeReleased(&database)
        tracker = nil
        apiClient = nil
        database = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_trackerSchedulesWorkItem_whenActiveLiveLocationIsInserted() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique
        let endAt = Date().addingTimeInterval(100) // 100 seconds in the future

        // Create current user and channel
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid)

        // Initially no work items should be scheduled
        XCTAssertTrue(tracker.workItems.isEmpty)

        // Create message with active live location
        try database.createMessage(
            id: messageId,
            authorId: currentUserId,
            cid: cid,
            location: .init(
                channelId: cid.rawValue,
                messageId: messageId,
                userId: currentUserId,
                latitude: 10.0,
                longitude: 20.0,
                createdAt: Date(),
                updatedAt: Date(),
                endAt: endAt,
                createdByDeviceId: .unique
            )
        )

        // Verify work item is scheduled
        AssertAsync.willBeEqual(tracker.workItems.count, 1)
        XCTAssertNotNil(tracker.workItems[messageId])
        XCTAssertFalse(tracker.workItems[messageId]?.isCancelled ?? true)
    }

    func test_trackerSchedulesMultipleWorkItems_forMultipleActiveLiveLocations() throws {
        let cid: ChannelId = .unique
        let messageId1: MessageId = .unique
        let messageId2: MessageId = .unique
        let currentUserId: UserId = .unique
        let endAt = Date().addingTimeInterval(100)

        // Create current user and channel
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid)

        // Create first message with active live location
        try database.createMessage(
            id: messageId1,
            authorId: currentUserId,
            cid: cid,
            location: .init(
                channelId: cid.rawValue,
                messageId: messageId1,
                userId: currentUserId,
                latitude: 10.0,
                longitude: 20.0,
                createdAt: Date(),
                updatedAt: Date(),
                endAt: endAt,
                createdByDeviceId: .unique
            )
        )

        // Create second message with active live location
        try database.createMessage(
            id: messageId2,
            authorId: currentUserId,
            cid: cid,
            location: .init(
                channelId: cid.rawValue,
                messageId: messageId2,
                userId: currentUserId,
                latitude: 30.0,
                longitude: 40.0,
                createdAt: Date(),
                updatedAt: Date(),
                endAt: endAt,
                createdByDeviceId: .unique
            )
        )

        // Verify both work items are scheduled
        AssertAsync.willBeEqual(tracker.workItems.count, 2)
        XCTAssertNotNil(tracker.workItems[messageId1])
        XCTAssertNotNil(tracker.workItems[messageId2])
        XCTAssertFalse(tracker.workItems[messageId1]?.isCancelled ?? true)
        XCTAssertFalse(tracker.workItems[messageId2]?.isCancelled ?? true)
    }

    func test_trackerCancelsWorkItem_whenActiveLiveLocationIsInactive() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique
        let endAt = Date().addingTimeInterval(100)
        let updatedAt = Date.unique

        // Create current user and channel
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid)

        // Create message with active live location
        try database.createMessage(
            id: messageId,
            authorId: currentUserId,
            cid: cid,
            location: .init(
                channelId: cid.rawValue,
                messageId: messageId,
                userId: currentUserId,
                latitude: 10.0,
                longitude: 20.0,
                createdAt: Date(),
                updatedAt: updatedAt,
                endAt: endAt,
                createdByDeviceId: .unique
            )
        )

        // Verify work item is scheduled
        AssertAsync.willBeEqual(tracker.workItems.count, 1)

        // Delete the message
        try database.writeSynchronously { session in
            let message = session.message(id: messageId)
            message?.location?.endAt = .distantPast.bridgeDate
            message?.isActiveLiveLocation = false
        }

        // Verify work item is removed
        AssertAsync.willBeEqual(tracker.workItems.count, 0)
        let newUpdatedAt = try XCTUnwrap(database.viewContext.message(id: messageId)?.updatedAt)
        // The updateAt should be updated especially to trigger an UI Update.
        XCTAssertNotEqual(String(newUpdatedAt.timeIntervalSince1970), String(updatedAt.timeIntervalSince1970))
    }

    func test_trackerDoesNotScheduleWorkItem_forMessageWithoutEndTime() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique

        // Create current user and channel
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid)

        // Create message with location but no endAt (static location)
        try database.createMessage(
            id: messageId,
            authorId: currentUserId,
            cid: cid,
            location: .init(
                channelId: cid.rawValue,
                messageId: messageId,
                userId: currentUserId,
                latitude: 10.0,
                longitude: 20.0,
                createdAt: Date(),
                updatedAt: Date(),
                endAt: nil, // No end time
                createdByDeviceId: .unique
            )
        )

        // No work item should be scheduled since there's no endAt
        AssertAsync.staysTrue(tracker.workItems.isEmpty)
    }

    func test_trackerDoesNotRetainItself() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique
        let endAt = Date().addingTimeInterval(100)

        // Create current user and channel
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid)

        // Create message with active live location
        try database.createMessage(
            id: messageId,
            authorId: currentUserId,
            cid: cid,
            location: .init(
                channelId: cid.rawValue,
                messageId: messageId,
                userId: currentUserId,
                latitude: 10.0,
                longitude: 20.0,
                createdAt: Date(),
                updatedAt: Date(),
                endAt: endAt,
                createdByDeviceId: .unique
            )
        )

        // Verify work item is scheduled
        AssertAsync.willBeEqual(tracker.workItems.count, 1)

        // Assert tracker can be released even though work items are scheduled
        AssertAsync.canBeReleased(&tracker)
    }
}
