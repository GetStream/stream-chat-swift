//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MissingEventsPayload_Tests: XCTestCase {
    func test_missingEventsPayload_isDeserialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MissingEventsPayload")
        let payload = try JSONDecoder.default.decode(SyncResponse.self, from: json)
        XCTAssertEqual(payload.events.count, 1)

        let expectedUser = UserObject(
            id: "broken-waterfall-5",
            banned: false,
            createdAt: "2019-12-12T15:33:46.488935Z".toDate(),
            deactivatedAt: nil,
            deletedAt: nil,
            invisible: false,
            language: nil,
            lastActive: "2020-09-07T12:25:41.501574Z".toDate(),
            online: true,
            revokeTokensIssuedBefore: nil,
            role: "user",
            updatedAt: "2020-09-07T12:27:43.096437Z".toDate(),
            custom: [:]
        )

        let event = try XCTUnwrap(payload.events.first).rawValue as! MessageNewEvent
        XCTAssertEqual(event.type, "message.new")
        XCTAssertEqual(event.cid, "messaging:A2F4393C-D656-46B8-9A43-6148E9E62D7F")
        XCTAssertEqual(event.createdAt, "2020-09-07T12:25:50.702323Z".toDate())

        let message = try XCTUnwrap(event.message)
        XCTAssertEqual(message.id, "AD6B64F8-1A12-48AF-B246-09774FD1B748")
        XCTAssertEqual(message.text, "How are you?")
        XCTAssertEqual(message.type, "regular")
        XCTAssertTrue(message.latestReactions.isEmpty)
        XCTAssertTrue(message.ownReactions.isEmpty)
        XCTAssertTrue(message.reactionScores.isEmpty)
        XCTAssertTrue(message.reactionCounts.isEmpty)
        XCTAssertEqual(message.replyCount, 0)
        XCTAssertEqual(message.createdAt, "2020-09-07T12:25:50.702323Z".toDate())
        XCTAssertEqual(message.updatedAt, "2020-09-07T12:25:50.702324Z".toDate())
        XCTAssertTrue(message.mentionedUsers.isEmpty)
        XCTAssertFalse(message.silent)

        let messageUser = try XCTUnwrap(message.user)
        XCTAssertEqual(messageUser.id, expectedUser.id)
//        XCTAssertEqual(messageUser.name, expectedUser.name)
//        XCTAssertEqual(messageUser.imageURL, expectedUser.imageURL)
        XCTAssertEqual(messageUser.role, expectedUser.role)
        XCTAssertEqual(messageUser.createdAt, expectedUser.createdAt)
        XCTAssertEqual(messageUser.updatedAt, expectedUser.updatedAt)
        XCTAssertEqual(messageUser.lastActive, expectedUser.lastActive)
        XCTAssertEqual(messageUser.banned, expectedUser.banned)
        XCTAssertEqual(messageUser.online, expectedUser.online)
        XCTAssertEqual(messageUser.invisible, expectedUser.invisible)
        XCTAssertEqual(messageUser.custom, expectedUser.custom)

        let eventUser = try XCTUnwrap(event.user)
        XCTAssertEqual(eventUser.id, expectedUser.id)
        XCTAssertEqual(eventUser.role, expectedUser.role)
        XCTAssertEqual(eventUser.createdAt, expectedUser.createdAt)
        XCTAssertEqual(eventUser.updatedAt, expectedUser.updatedAt)
        XCTAssertEqual(eventUser.lastActive, expectedUser.lastActive)
        XCTAssertEqual(eventUser.banned, expectedUser.banned)
        XCTAssertEqual(eventUser.online, expectedUser.online)
        XCTAssertEqual(eventUser.invisible, expectedUser.invisible)
        XCTAssertEqual(eventUser.custom, expectedUser.custom)
    }

    func test_missingEventsPayload_incompleteChannels_isDeserialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MissingEventsPayload-IncompleteChannel")
        let payload = try JSONDecoder.default.decode(SyncResponse.self, from: json)
        XCTAssertEqual(payload.events.count, 4)

        let expectedTypes: [EventType] = [
            .notificationRemovedFromChannel,
            .notificationAddedToChannel,
            .notificationRemovedFromChannel,
            .notificationAddedToChannel
        ]

        let first = payload.events[0].rawValue as! NotificationRemovedFromChannelEvent
        XCTAssertNil(first.channel)
        XCTAssertEqual(first.user?.id, "broken-waterfall-5")
        XCTAssertEqual(first.createdAt, "2020-09-07T12:25:50.702323Z".toDate())
        XCTAssertEqual(first.type, expectedTypes[0].rawValue)
        
        let second = payload.events[1].rawValue as! NotificationAddedToChannelEvent
        XCTAssertNil(second.channel)
        XCTAssertEqual(second.createdAt, "2020-09-07T12:25:50.702323Z".toDate())
        XCTAssertEqual(second.type, expectedTypes[1].rawValue)
        
        let third = payload.events[2].rawValue as! NotificationRemovedFromChannelEvent
        XCTAssertNil(third.channel)
        XCTAssertEqual(third.user?.id, "broken-waterfall-5")
        XCTAssertEqual(third.createdAt, "2020-09-07T12:25:50.702323Z".toDate())
        XCTAssertEqual(third.type, expectedTypes[2].rawValue)
        
        let fourth = payload.events[3].rawValue as! NotificationAddedToChannelEvent
        XCTAssertNil(fourth.channel)
        XCTAssertEqual(fourth.createdAt, "2020-09-07T12:25:50.702323Z".toDate())
        XCTAssertEqual(fourth.type, expectedTypes[3].rawValue)
    }
}
