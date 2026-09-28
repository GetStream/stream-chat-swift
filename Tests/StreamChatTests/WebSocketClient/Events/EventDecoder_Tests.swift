//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EventDecoder_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    // MARK: System events

    func test_decode_whenValidSystemEventPayloadComes_returnsDecodedSystemEvent() throws {
        // Load valid system event JSON.
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel")

        // Decode an event.
        let event = try eventDecoder.decode(from: json)

        // Assert system event is decoded.
        XCTAssertTrue((event as? WSEvent)?.rawValue is NotificationAddedToChannelEventDTO)
    }

    func test_decode_whenInvalidSystemEventPayloadComes_throwsEventDecodingError() throws {
        // Create invalid system event JSON
        let json = """
        {
            "type" : "\(EventType.notificationInvited.rawValue)"
        }
        """.data(using: .utf8)!

        // Assert decoding error is thrown.
        XCTAssertThrowsError(try eventDecoder.decode(from: json)) { error in
            XCTAssertTrue(error is ClientError.EventDecoding)
        }
    }

    func test_decode_whenKnownEventTypeFailsToDecode_throwsInsteadOfReturningUnknownEvent() throws {
        // Create a `message.new` event JSON which is missing the required `message` field but carries
        // everything `UnknownChannelEvent` needs.
        let json = """
        {
            "user" : {
                "id" : "\(UserId.unique)",
                "banned" : false,
                "created_at" : "2019-12-12T15:33:46.488935Z",
                "updated_at" : "2020-07-16T15:38:10.289007Z",
                "role" : "user",
                "online" : true
            },
            "cid" : "\(ChannelId.unique.rawValue)",
            "created_at" : "2020-07-16T15:38:10.289007Z",
            "type" : "\(EventType.messageNew.rawValue)",
            "custom" : {}
        }
        """.data(using: .utf8)!

        // Assert decoding error is thrown instead of the event being reported as unknown.
        XCTAssertThrowsError(try eventDecoder.decode(from: json)) { error in
            XCTAssertTrue(error is ClientError.EventDecoding)
        }
    }

    func test_decode_whenChannelCreatedEventComes_throwsIgnoredEventTypeError() throws {
        // Load channel created event JSON.
        let json = XCTestCase.mockData(fromJSONFile: "ChannelCreated")

        // Assert ignored event type error is thrown.
        XCTAssertThrowsError(try eventDecoder.decode(from: json)) { error in
            XCTAssertTrue(error is ClientError.IgnoredEventType)
        }
    }

    func test_decode_whenHealthCheckEventComesWithNumericCreatedAt_returnsWSEvent() throws {
        // Create health check event JSON with a numeric timestamp.
        let json = """
        {
            "type" : "health.check",
            "created_at" : 1758540000.5,
            "connection_id" : "x",
            "custom" : {}
        }
        """.data(using: .utf8)!

        // Decode an event.
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? WSEvent)

        // Assert health check info is available.
        XCTAssertEqual(event.healthcheck()?.connectionId, "x")
    }

    // MARK: Connection events

    func test_decode_whenConnectionOkComes_returnsConnectedEvent() throws {
        // Create connection.ok event JSON.
        let connectionId: String = .unique
        var json = [String: Any].healthCheckEvent(userId: .unique, connectionId: connectionId)
        json["type"] = EventType.connectionOk.rawValue
        let data = try JSONSerialization.data(withJSONObject: json)

        // Decode an event.
        let event = try XCTUnwrap(try eventDecoder.decode(from: data) as? ConnectedEvent)

        // Assert event has correct fields.
        XCTAssertEqual(event.connectionId, connectionId)
        XCTAssertEqual(event.healthcheck()?.connectionId, connectionId)
        XCTAssertNotNil(event.me)
    }

    func test_decode_whenConnectionOkComesWithoutMe_returnsConnectedEvent() throws {
        // Create connection.ok event JSON without the current user.
        let connectionId: String = .unique
        var json = [String: Any].healthCheckEvent(userId: .unique, connectionId: connectionId)
        json["type"] = EventType.connectionOk.rawValue
        json.removeValue(forKey: "me")
        let data = try JSONSerialization.data(withJSONObject: json)

        // Decode an event.
        let event = try XCTUnwrap(try eventDecoder.decode(from: data) as? ConnectedEvent)

        // Assert event has correct fields.
        XCTAssertEqual(event.healthcheck()?.connectionId, connectionId)
        XCTAssertNil(event.me)
    }

    func test_decode_whenConnectionErrorComes_returnsConnectionErrorEvent() throws {
        // Create connection.error event JSON.
        let json = """
        {
            "type" : "connection.error",
            "created_at" : "2020-07-16T15:38:10.289007Z",
            "connection_id" : "x",
            "error" : {
                "code" : 40,
                "message" : "token expired",
                "StatusCode" : 401,
                "duration" : "1ms",
                "more_info" : "",
                "details" : []
            }
        }
        """.data(using: .utf8)!

        // Decode an event.
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ConnectionErrorEvent)

        // Assert the error is available.
        XCTAssertNotNil(event.error())
    }

    // MARK: Custom events

    func test_decode_whenValidCustomEventPayloadComes_returnsUnknownChannelEvent() throws {
        // Create custom event fields
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let ideaPayload: IdeaEventPayload = .unique
        let createdAt: String = "2020-07-16T15:38:10.289007Z"

        // Create custom event JSON
        let json = """
        {
            "user" : {
                "id" : "\(userId)",
                "banned" : false,
                "unread_channels" : 0,
                "totalUnreadCount" : 0,
                "created_at" : "2019-12-12T15:33:46.488935Z",
                "invisible" : false,
                "unreadChannels" : 0,
                "unread_count" : 0,
                "image" : "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall",
                "updated_at" : "2020-07-16T15:38:10.289007Z",
                "role" : "user",
                "total_unread_count" : 0,
                "online" : true,
                "name" : "broken-waterfall-5"
            },
            "channel_type" : "\(cid.type.rawValue)",
            "channel_id" : "\(cid.id)",
            "cid" : "\(cid.rawValue)",
            "created_at" : "\(createdAt)",
            "type" : "\(IdeaEventPayload.eventType.rawValue)",
            "custom" : {
                "idea" : "\(ideaPayload.idea)"
            }
        }
        """.data(using: .utf8)!

        // Assert event is decoded.
        let event = try eventDecoder.decode(from: json)
        // Assert `UnknownChannelEvent` event with expected payload is decoded
        let unknownEvent = try XCTUnwrap(event as? UnknownChannelEvent)

        // Assert event has correct fields.
        XCTAssertEqual(unknownEvent.cid, cid)
        XCTAssertEqual(unknownEvent.userId, userId)
        XCTAssertEqual(unknownEvent.createdAt, createdAt.toDate())
        XCTAssertEqual(unknownEvent.payload(ofType: IdeaEventPayload.self), ideaPayload)
    }

    func test_decode_whenValidCustomEventPayloadComes_returnsUnknownUserEvent() throws {
        // Create custom event fields
        let userId: UserId = .unique
        let ideaPayload: IdeaEventPayload = .unique
        let createdAt: String = "2020-07-16T15:38:10.289007Z"

        // Create custom event JSON
        let json = """
        {
            "user" : {
                "id" : "\(userId)",
                "banned" : false,
                "created_at" : "2019-12-12T15:33:46.488935Z",
                "invisible" : false,
                "unreadChannels" : 0,
                "extra_uid" : 2000,
                "unread_count" : 0,
                "image" : "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall",
                "updated_at" : "2020-07-16T15:38:10.289007Z",
                "role" : "user",
                "total_unread_count" : 0,
                "online" : true,
                "name" : "broken-waterfall-5"
            },
            "created_at" : "\(createdAt)",
            "type" : "\(IdeaEventPayload.eventType.rawValue)",
            "custom" : {
                "idea" : "\(ideaPayload.idea)"
            }
        }
        """.data(using: .utf8)!

        // Assert event is decoded.
        let event = try eventDecoder.decode(from: json)
        // Assert `UnknownUserEvent` event with expected payload is decoded
        let unknownEvent = try XCTUnwrap(event as? UnknownUserEvent)

        // Assert event has correct fields.
        XCTAssertEqual(unknownEvent.userId, userId)
        XCTAssertEqual(unknownEvent.createdAt, createdAt.toDate())
        XCTAssertEqual(unknownEvent.payload(ofType: IdeaEventPayload.self), ideaPayload)
    }

    func test_decode_whenValidV2CustomEventPayloadComes_preservesUnknownChannelEventEnvelope() throws {
        // Create custom event fields
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let createdAt: String = "2020-07-16T15:38:10.289007Z"

        // Create v2 custom event JSON with the custom data nested under `custom`
        let json = """
        {
            "user" : {
                "id" : "\(userId)",
                "banned" : false,
                "created_at" : "2019-12-12T15:33:46.488935Z",
                "updated_at" : "2020-07-16T15:38:10.289007Z",
                "role" : "user",
                "online" : true
            },
            "cid" : "\(cid.rawValue)",
            "created_at" : "\(createdAt)",
            "type" : "\(IdeaEventPayload.eventType.rawValue)",
            "custom" : {
                "idea" : "flatten me"
            }
        }
        """.data(using: .utf8)!

        // Assert `UnknownChannelEvent` event with its v2 envelope is decoded.
        let unknownEvent = try XCTUnwrap(try eventDecoder.decode(from: json) as? UnknownChannelEvent)

        // Assert event has correct fields.
        XCTAssertEqual(unknownEvent.cid, cid)
        XCTAssertEqual(unknownEvent.userId, userId)
        XCTAssertEqual(unknownEvent.createdAt, createdAt.toDate())
        XCTAssertEqual(unknownEvent.payload(ofType: IdeaEventPayload.self)?.idea, "flatten me")
        XCTAssertEqual(unknownEvent.payload["custom"], ["idea": .string("flatten me")])
        XCTAssertNil(unknownEvent.payload["idea"])
    }

    func test_decode_whenInvalidCustomEventPayloadComes_throwsDecodingError() {
        // Create invalid custom channel event JSON
        let json = """
        {
            "type" : "\(IdeaEventPayload.eventType.rawValue)"
        }
        """.data(using: .utf8)!

        // Assert error is thrown.
        XCTAssertThrowsError(try eventDecoder.decode(from: json)) { error in
            XCTAssertTrue(error is ClientError.EventDecoding)
        }
    }
}
