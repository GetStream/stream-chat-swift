//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelVisibilityEventMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: ChannelVisibilityEventMiddleware!

    // MARK: - Set up

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
        middleware = .init()
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }

    // MARK: - Tests

    func test_middleware_forwardsOtherEvents() throws {
        let event = TestEvent()

        // Handle non-reaction event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }

    func test_middleware_forwardsTheEvent_ifDatabaseWriteGeneratesError() throws {
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle channel hidden event.
        let hiddenEvent = makeChannelHiddenEventDTO(cid: .unique, clearHistory: false)
        var forwardedEvent = middleware.handle(event: hiddenEvent, session: database.viewContext)

        // Assert `ChannelTruncatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ChannelHiddenEventDTO)

        // Simulate and handle channel hidden event.
        let visibleEvent = makeChannelVisibleEventDTO(cid: .unique)
        forwardedEvent = middleware.handle(event: visibleEvent, session: database.viewContext)

        // Assert `ChannelTruncatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ChannelVisibleEventDTO)
    }

    func test_middlewareCanSeePendingEntities() throws {
        let cid = ChannelId.unique

        // Create the event
        let event = makeChannelHiddenEventDTO(cid: cid, clearHistory: false)

        // Open a database session to simulate EventNotificationCenter
        try database.writeSynchronously {
            try $0.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            // Handle the event
            _ = self.middleware.handle(event: event, session: $0)
        }

        // Check if the channel was found and marked as hidden
        XCTAssertEqual(database.viewContext.channel(cid: cid)?.isHidden, true)
    }

    func test_channelHiddenEvent_updateChannelHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeChannelHiddenEventDTO(cid: cid, clearHistory: false)

        try database.createChannel(cid: cid, withMessages: true)

        // Assert `isHidden` is `false` by default
        assert(database.viewContext.channel(cid: cid)?.isHidden == false)

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is updated
        XCTAssertTrue(channelDTO.isHidden)

        // Assert the `truncatedAt` value is not touched
        XCTAssertNil(channelDTO.truncatedAt)
        XCTAssert(forwardedEvent is ChannelHiddenEventDTO)
    }

    func test_channelHiddenEvent_truncatesChannelWhenHistoryIsCleared() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeChannelHiddenEventDTO(cid: cid, clearHistory: true)

        try database.createChannel(cid: cid, withMessages: true)

        // Assert `truncatedAt` is `nil` by default
        assert(database.viewContext.channel(cid: cid)?.truncatedAt == nil)

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert the `truncatedAt` value is not touched
        XCTAssertEqual(channelDTO.truncatedAt?.bridgeDate, event.createdAt)
        XCTAssert(forwardedEvent is ChannelHiddenEventDTO)
    }

    func test_channelVisibleEvent_resetsHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeChannelVisibleEventDTO(cid: cid)

        // Create a channel in the DB with `isHidden` and `truncatedAt` values
        let originalTruncatedAt = Date.unique
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
            dto.truncatedAt = originalTruncatedAt.bridgeDate
        }

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is reset
        XCTAssertFalse(channelDTO.isHidden)

        // Assert the `truncatedAt` value is not touched
        XCTAssertEqual(channelDTO.truncatedAt?.bridgeDate, originalTruncatedAt)
        XCTAssert(forwardedEvent is ChannelVisibleEventDTO)
    }

    func test_messageNewEvent_resetsHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeMessageNewEventDTO(cid: cid, message: .dummy(messageId: .unique, authorUserId: .unique))

        // Create a channel in the DB with `isHidden` set to true
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
        }

        // Simulate incoming event
        _ = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is reset
        XCTAssertFalse(channelDTO.isHidden)
    }

    func test_messageNewEvent_whenShadowedMessage_doesNotResetsHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeMessageNewEventDTO(cid: cid, message: .dummy(messageId: .unique, authorUserId: .unique, isShadowed: true))

        // Create a channel in the DB with `isHidden` set to true
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
        }

        // Simulate incoming event
        _ = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is still true
        XCTAssertTrue(channelDTO.isHidden)
    }

    func test_messageNewEvent_whenCampaignMessage_doesNotResetIsHidden() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeMessageNewEventDTO(cid: cid, message: .dummy(messageId: .unique, authorUserId: .unique, campaignId: "campaign_123"))

        // Create a channel in the DB with `isHidden` set to true
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
        }

        // Simulate incoming event
        _ = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is still true
        XCTAssertTrue(channelDTO.isHidden)
    }

    func test_notificationMessageNewEvent_resetsHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeNotificationNewMessageEventDTO(cid: cid, message: .dummy(messageId: .unique, authorUserId: .unique))

        // Create a channel in the DB with `isHidden` set to true
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
        }

        // Simulate incoming event
        _ = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is reset
        XCTAssertFalse(channelDTO.isHidden)
    }

    func test_notificationMessageNewEvent_whenShadowedMessage_doesNotResetsHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeNotificationNewMessageEventDTO(cid: cid, message: .dummy(messageId: .unique, authorUserId: .unique, isShadowed: true))

        // Create a channel in the DB with `isHidden` set to true
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
        }

        // Simulate incoming event
        _ = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is still true
        XCTAssertTrue(channelDTO.isHidden)
    }

    func test_notificationMessageNewEvent_whenCampaignMessage_doesNotResetIsHidden() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = makeNotificationNewMessageEventDTO(cid: cid, message: .dummy(messageId: .unique, authorUserId: .unique, campaignId: "campaign_123"))

        // Create a channel in the DB with `isHidden` set to true
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
        }

        // Simulate incoming event
        _ = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is still true
        XCTAssertTrue(channelDTO.isHidden)
    }

    // MARK: - Helpers

    private func makeChannelHiddenEventDTO(cid: ChannelId, clearHistory: Bool) -> ChannelHiddenEventDTO {
        ChannelHiddenEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            clearHistory: clearHistory,
            createdAt: .unique,
            custom: [:],
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )
    }

    private func makeChannelVisibleEventDTO(cid: ChannelId) -> ChannelVisibleEventDTO {
        ChannelVisibleEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )
    }

    private func makeMessageNewEventDTO(cid: ChannelId, message: MessageResponse) -> MessageNewEventDTO {
        MessageNewEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: message,
            messageId: message.id,
            user: UserResponseCommonFields(.dummy(userId: .unique)),
            watcherCount: 0
        )
    }

    private func makeNotificationNewMessageEventDTO(cid: ChannelId, message: MessageResponse) -> NotificationNewMessageEventDTO {
        NotificationNewMessageEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: message,
            messageId: message.id,
            watcherCount: 0
        )
    }
}
