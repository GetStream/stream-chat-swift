//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MissingEventsPayload_Tests: XCTestCase {
    func test_missingEventsPayload_isDeserialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MissingEventsPayload")
        let payload = try JSONDecoder.default.decode(SyncResponse.self, from: json)
        XCTAssertEqual(payload.events.count, 1)

        let expectedUser = UserPayload.dummy(
            userId: "broken-waterfall-5",
            name: "Broken Waterfall",
            imageUrl: URL(string: "https://api.adorable.io/avatars/285/broken-waterfall-5.png"),
            role: .user,
            teams: [],
            createdAt: "2019-12-12T15:33:46.488935Z".toDate(),
            updatedAt: "2020-09-07T12:27:43.096437Z".toDate(),
            lastActiveAt: "2020-09-07T12:25:41.501574Z".toDate()
        )

        guard case let .typeMessageNewEvent(event) = try XCTUnwrap(payload.events.first) else {
            return XCTFail("Expected a message.new event")
        }
        XCTAssertEqual(event.cid.rawValue, "messaging:A2F4393C-D656-46B8-9A43-6148E9E62D7F")
        XCTAssertEqual(event.createdAt, "2020-09-07T12:25:50.702323Z".toDate())

        let message = event.message
        XCTAssertEqual(message.id, "AD6B64F8-1A12-48AF-B246-09774FD1B748")
        XCTAssertEqual(message.text, "How are you?")
        XCTAssertEqual(message.type, MessageType.regular.rawValue)
        XCTAssertTrue(message.latestReactions.isEmpty)
        XCTAssertTrue(message.ownReactions.isEmpty)
        XCTAssertTrue(message.reactionScores.isEmpty)
        XCTAssertTrue(message.reactionCounts?.isEmpty ?? true)
        XCTAssertEqual(message.replyCount, 0)
        XCTAssertEqual(message.createdAt, "2020-09-07T12:25:50.702323Z".toDate())
        XCTAssertEqual(message.updatedAt, "2020-09-07T12:25:50.702324Z".toDate())
        XCTAssertTrue(message.mentionedUsers.isEmpty)
        XCTAssertFalse(message.silent)

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
        XCTAssertEqual(messageUser.extraData, expectedUser.extraData)

        let eventUser = try XCTUnwrap(event.user)
        XCTAssertEqual(eventUser.id, expectedUser.id)
        XCTAssertEqual(eventUser.role, expectedUser.role)
        XCTAssertEqual(eventUser.createdAt, expectedUser.createdAt)
        XCTAssertEqual(eventUser.updatedAt, expectedUser.updatedAt)
        XCTAssertEqual(eventUser.lastActiveAt, expectedUser.lastActiveAt)
        XCTAssertEqual(eventUser.isBanned, expectedUser.isBanned)
        XCTAssertEqual(eventUser.isOnline, expectedUser.isOnline)
        XCTAssertEqual(eventUser.extraData, expectedUser.extraData)
    }

    func test_missingEventsPayload_incompleteChannels_isDeserialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MissingEventsPayload-IncompleteChannel")
        let payload = try JSONDecoder.default.decode(SyncResponse.self, from: json)
        XCTAssertTrue(payload.events.isEmpty)
    }

    func test_missingEventsPayload_skipsUndecodableEvents() throws {
        let data = XCTestCase.mockData(fromJSONFile: "MissingEventsPayload")
        var json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var events = try XCTUnwrap(json["events"] as? [[String: Any]])
        events.append([
            "type": "channel.frozen",
            "cid": "messaging:123",
            "channel_id": "123",
            "channel_type": "messaging",
            "created_at": "2020-09-07T12:25:51.702323Z",
            "custom": [String: Any]()
        ])
        events.append([
            "type": "custom_event_type",
            "cid": "messaging:123",
            "created_at": "2020-09-07T12:25:52.702323Z"
        ])
        json["events"] = events

        let payload = try JSONDecoder.default.decode(
            SyncResponse.self,
            from: try JSONSerialization.data(withJSONObject: json)
        )

        XCTAssertEqual(payload.events.count, 1)
        guard case let .typeMessageNewEvent(event) = try XCTUnwrap(payload.events.first) else {
            return XCTFail("Expected a message.new event")
        }
        XCTAssertEqual(event.message.id, "AD6B64F8-1A12-48AF-B246-09774FD1B748")
    }
}
