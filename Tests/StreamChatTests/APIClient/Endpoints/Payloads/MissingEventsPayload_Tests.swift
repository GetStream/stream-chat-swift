//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MissingEventsPayload_Tests: XCTestCase {
    func test_missingEventsPayload_isDeserialized() throws {
        let json = XCTestCase.mockData(fromFile: "MissingEventsPayload")
        let payload = try JSONDecoder.default.decode(MissingEventsPayload.self, from: json)
        XCTAssertEqual(payload.eventPayloads.count, 1)
        
        let expectedUser = UserPayload(
            id: "broken-waterfall-5",
            name: "Broken Waterfall",
            imageURL: URL(string: "https://api.adorable.io/avatars/285/broken-waterfall-5.png"),
            role: .user,
            createdAt: "2019-12-12T15:33:46.488935Z".toDate(),
            updatedAt: "2020-09-07T12:27:43.096437Z".toDate(),
            lastActiveAt: "2020-09-07T12:25:41.501574Z".toDate(),
            isOnline: true,
            isInvisible: false,
            isBanned: false,
            extraData: [:]
        )
        
        let event = try XCTUnwrap(payload.eventPayloads.first)
        XCTAssertEqual(event.eventType, .messageNew)
        XCTAssertEqual(event.cid?.rawValue, "messaging:A2F4393C-D656-46B8-9A43-6148E9E62D7F")
        XCTAssertEqual(event.createdAt, "2020-09-07T12:25:50.702323Z".toDate())

        let message = try XCTUnwrap(event.message)
        XCTAssertEqual(message.id, "AD6B64F8-1A12-48AF-B246-09774FD1B748")
        XCTAssertEqual(message.text, "How are you?")
        XCTAssertEqual(message.type, .regular)
        XCTAssertTrue(message.latestReactions.isEmpty)
        XCTAssertTrue(message.ownReactions.isEmpty)
        XCTAssertTrue(message.reactionScores.isEmpty)
        XCTAssertTrue(message.reactionCounts.isEmpty)
        XCTAssertEqual(message.replyCount, 0)
        XCTAssertEqual(message.createdAt, "2020-09-07T12:25:50.702323Z".toDate())
        XCTAssertEqual(message.updatedAt, "2020-09-07T12:25:50.702324Z".toDate())
        XCTAssertTrue(message.mentionedUsers.isEmpty)
        XCTAssertFalse(message.isSilent)

        let messageUser = try XCTUnwrap(message.user)
        XCTAssertEqual(messageUser.id, expectedUser.id)
        XCTAssertEqual(messageUser.name, expectedUser.name)
        XCTAssertEqual(messageUser.imageURL, expectedUser.imageURL)
        XCTAssertEqual(messageUser.role, expectedUser.role)
        XCTAssertEqual(messageUser.createdAt, expectedUser.createdAt)
        XCTAssertEqual(messageUser.updatedAt, expectedUser.updatedAt)
        XCTAssertEqual(messageUser.lastActiveAt, expectedUser.lastActiveAt)
        XCTAssertEqual(messageUser.isBanned, expectedUser.isBanned)
        XCTAssertEqual(messageUser.isOnline, expectedUser.isOnline)
        XCTAssertEqual(messageUser.isInvisible, expectedUser.isInvisible)
        XCTAssertEqual(messageUser.extraData, expectedUser.extraData)
        
        let eventUser = try XCTUnwrap(event.user)
        XCTAssertEqual(eventUser.id, expectedUser.id)
        XCTAssertEqual(eventUser.role, expectedUser.role)
        XCTAssertEqual(eventUser.createdAt, expectedUser.createdAt)
        XCTAssertEqual(eventUser.updatedAt, expectedUser.updatedAt)
        XCTAssertEqual(eventUser.lastActiveAt, expectedUser.lastActiveAt)
        XCTAssertEqual(eventUser.isBanned, expectedUser.isBanned)
        XCTAssertEqual(eventUser.isOnline, expectedUser.isOnline)
        XCTAssertEqual(eventUser.isInvisible, expectedUser.isInvisible)
        XCTAssertEqual(eventUser.extraData, expectedUser.extraData)
    }
}
