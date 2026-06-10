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
        let wsEvent = try XCTUnwrap(event as? WSEvent)
        XCTAssertTrue(wsEvent.rawValue is NotificationAddedToChannelEventDTO)
        XCTAssertEqual(wsEvent.type, EventType.notificationAddedToChannel.rawValue)
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

    func test_decode_whenWSEventComes_returnsWSEvent() throws {
        let cid = ChannelId.unique
        let messageId = MessageId.unique
        let sourceEvent = WSEvent.typeMessageNewEvent(
            MessageNewEventDTO(
                cid: cid.rawValue,
                createdAt: .unique,
                custom: [:],
                message: .dummy(messageId: messageId, authorUserId: .unique, latestReactions: [], channel: .dummy(cid: cid)),
                messageId: messageId,
                user: UserResponseCommonFields.dummy(userId: ""),
                watcherCount: 0
            )
        )

        let event = try eventDecoder.decode(from: sourceEvent)

        let wsEvent = try XCTUnwrap(event as? WSEvent)
        XCTAssertTrue(wsEvent.rawValue is MessageNewEventDTO)
        XCTAssertEqual(wsEvent, sourceEvent)
    }

    func test_decode_whenHealthCheckWSEventComes_returnsWSEventWithHealthCheckInfo() throws {
        let connectionId = String.unique
        let sourceEvent = WSEvent.typeHealthCheckEvent(
            HealthCheckEventDTO(
                connectionId: connectionId,
                createdAt: .unique,
                custom: [:]
            )
        )

        let event = try eventDecoder.decode(from: sourceEvent)

        let wsEvent = try XCTUnwrap(event as? WSEvent)
        XCTAssertEqual(wsEvent, sourceEvent)
        XCTAssertNotNil(wsEvent.healthcheck())
        XCTAssertEqual(wsEvent.healthcheck()?.connectionId, connectionId)
    }

    func test_decode_whenHealthCheckPayloadComes_returnsHealthCheckEvent() throws {
        // Decoded directly (not from a fixture) so the v2 wire format is exercised as-is.
        // The v2 transport encodes dates as unix-nanosecond numbers, which also
        // exercises the numeric branch of the date decoding strategy.
        let connectionId = String.unique
        let json = """
        {
            "connection_id": "\(connectionId)",
            "cid": "*",
            "type": "health.check",
            "custom": {},
            "created_at": 1781082614102925808
        }
        """.data(using: .utf8)!

        let event = try eventDecoder.decode(from: json)

        let wsEvent = try XCTUnwrap(event as? WSEvent)
        let healthCheck = try XCTUnwrap(wsEvent.rawValue as? HealthCheckEventDTO)
        XCTAssertEqual(healthCheck.connectionId, connectionId)
        XCTAssertEqual(wsEvent.healthcheck()?.connectionId, connectionId)
    }

    func test_decode_whenConnectionOkComes_returnsConnectedEventWithHealthCheckInfoAndMe() throws {
        // The v2 connect hello carries the own user in `me`. Mute entries arrive
        // without nested target/channel data and dates are unix-nanosecond numbers.
        let connectionId = String.unique
        let json = """
        {
            "type": "connection.ok",
            "connection_id": "\(connectionId)",
            "created_at": 1781082614102925808,
            "me": {
                "id": "luke_skywalker",
                "name": "Luke Skywalker",
                "role": "user",
                "banned": false,
                "online": true,
                "invisible": false,
                "language": "en",
                "teams": [],
                "custom": {},
                "devices": [],
                "mutes": [
                    {"created_at": 1765825016623238000, "updated_at": 1765825016623238000}
                ],
                "channel_mutes": [
                    {"created_at": 1780313582149449000, "updated_at": 1780313582149449000}
                ],
                "total_unread_count": 1,
                "unread_channels": 1,
                "unread_count": 1,
                "unread_threads": 0,
                "created_at": 1712222771805899000,
                "updated_at": 1779616625240451000
            },
            "chat": {
                "total_unread_count": 1,
                "unread_channels": 1,
                "unread_threads": 0,
                "mutes": [],
                "channel_mutes": []
            }
        }
        """.data(using: .utf8)!

        let event = try eventDecoder.decode(from: json)

        let connectedEvent = try XCTUnwrap(event as? ConnectedEvent)
        XCTAssertEqual(connectedEvent.connectionId, connectionId)
        XCTAssertEqual(connectedEvent.healthcheck()?.connectionId, connectionId)
        let me = try XCTUnwrap(connectedEvent.me)
        XCTAssertEqual(me.id, "luke_skywalker")
        XCTAssertEqual(me.totalUnreadCount, 1)
        XCTAssertEqual(me.channelMutes.count, 1)
    }

    func test_decode_whenConnectionOkHasNoMe_returnsConnectedEvent() throws {
        let connectionId = String.unique
        let json = """
        {
            "type": "connection.ok",
            "connection_id": "\(connectionId)",
            "created_at": 1781082614102925808
        }
        """.data(using: .utf8)!

        let event = try eventDecoder.decode(from: json)

        let connectedEvent = try XCTUnwrap(event as? ConnectedEvent)
        XCTAssertEqual(connectedEvent.connectionId, connectionId)
        XCTAssertNil(connectedEvent.me)
    }

    func test_decode_whenConnectionOkHasNoConnectionId_throwsEventDecodingError() throws {
        let json = """
        {
            "type": "connection.ok"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try eventDecoder.decode(from: json)) { error in
            XCTAssertTrue(error is ClientError.EventDecoding)
        }
    }

    func test_decode_whenChannelCreatedWSEventComes_returnsWrappedRawEvent() throws {
        let cid = ChannelId.unique
        let sourceEvent = WSEvent.typeChannelCreatedEvent(
            ChannelCreatedEventDTO(
                channel: .dummy(cid: cid),
                cid: cid.rawValue,
                createdAt: .unique,
                custom: [:]
            )
        )

        let event = try eventDecoder.decode(from: sourceEvent)

        let wsEvent = try XCTUnwrap(event as? WSEvent)
        XCTAssertTrue(wsEvent.rawValue is ChannelCreatedEventDTO)
        XCTAssertEqual(wsEvent, sourceEvent)
    }

    func test_decode_whenGlobalUserBannedWSEventComes_wrapsRawUserBannedEvent() throws {
        let sourceEvent = WSEvent.typeUserBannedEvent(
            UserBannedEventDTO(
                createdAt: .unique,
                custom: [:],
                user: UserResponseCommonFields.dummy(userId: .unique)
            )
        )

        let event = try eventDecoder.decode(from: sourceEvent)

        let wsEvent = try XCTUnwrap(event as? WSEvent)
        XCTAssertTrue(wsEvent.rawValue is UserBannedEventDTO)
        XCTAssertEqual(wsEvent, sourceEvent)
    }

    func test_decode_whenGlobalUserUnbannedWSEventComes_wrapsRawUserUnbannedEvent() throws {
        let sourceEvent = WSEvent.typeUserUnbannedEvent(
            UserUnbannedEventDTO(
                createdAt: .unique,
                custom: [:],
                user: UserResponseCommonFields.dummy(userId: .unique)
            )
        )

        let event = try eventDecoder.decode(from: sourceEvent)

        let wsEvent = try XCTUnwrap(event as? WSEvent)
        XCTAssertTrue(wsEvent.rawValue is UserUnbannedEventDTO)
        XCTAssertEqual(wsEvent, sourceEvent)
    }

    func test_decode_whenMarkReadWithoutChannelWSEventComes_wrapsRawMarkReadEvent() throws {
        let sourceEvent = WSEvent.typeNotificationMarkReadEvent(
            NotificationMarkReadEventDTO(
                createdAt: .unique,
                custom: [:],
                totalUnreadCount: 2,
                unreadChannels: 1,
                unreadCount: 2,
                user: UserResponseCommonFields.dummy(userId: .unique)
            )
        )

        let event = try eventDecoder.decode(from: sourceEvent)

        let wsEvent = try XCTUnwrap(event as? WSEvent)
        XCTAssertTrue(wsEvent.rawValue is NotificationMarkReadEventDTO)
        XCTAssertEqual(wsEvent, sourceEvent)
    }

    func test_decode_whenConnectionErrorComes_returnsConnectionErrorEvent() throws {
        let json = """
        {
            "type": "\(EventType.connectionError.rawValue)",
            "error": {
                "code": 4,
                "details": [],
                "duration": "",
                "message": "connection failed",
                "more_info": "",
                "StatusCode": 500
            }
        }
        """.data(using: .utf8)!

        let event = try eventDecoder.decode(from: json)

        XCTAssertTrue(event is ConnectionErrorEvent)
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
                "name" : "broken-waterfall-5",
                "blocked_user_ids" : [],
                "custom" : {},
                "language" : "",
                "teams" : []
            },
            "channel_type" : "\(cid.type.rawValue)",
            "channel_id" : "\(cid.id)",
            "cid" : "\(cid.rawValue)",
            "created_at" : "\(createdAt)",
            "type" : "\(IdeaEventPayload.eventType.rawValue)",
            "idea" : "\(ideaPayload.idea)"
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
                "name" : "broken-waterfall-5",
                "blocked_user_ids" : [],
                "custom" : {},
                "language" : "",
                "teams" : []
            },
            "created_at" : "\(createdAt)",
            "type" : "\(IdeaEventPayload.eventType.rawValue)",
            "idea" : "\(ideaPayload.idea)"
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

extension EventDecoder {
    func decodeFixture(from data: Data) throws -> Event {
        try decode(from: EventDecoderFixtureNormalizer.normalize(data) ?? data)
    }
}

enum EventDecoderFixtureNormalizer {
    static func normalize(_ data: Data) -> Data? {
        guard var dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return nil
        }
        normalize(dict: &dict)
        return try? JSONSerialization.data(withJSONObject: dict)
    }

    private static func normalize(dict: inout [String: Any]) {
        let type = dict["type"] as? String

        if dict["message_id"] == nil,
           let message = dict["message"] as? [String: Any],
           let id = message["id"] as? String {
            dict["message_id"] = id
        }
        if dict["user_id"] == nil,
           let user = dict["user"] as? [String: Any],
           let id = user["id"] as? String {
            dict["user_id"] = id
        }
        if dict["thread_id"] == nil,
           let message = dict["message"] as? [String: Any],
           let parentId = message["parent_id"] as? String {
            dict["thread_id"] = parentId
        }
        if dict["cid"] == nil,
           let reminder = dict["reminder"] as? [String: Any],
           let channelCid = reminder["channel_cid"] as? String {
            dict["cid"] = channelCid
        }
        if dict["watcher_count"] == nil {
            dict["watcher_count"] = 0
        }
        if dict["hard_delete"] == nil {
            dict["hard_delete"] = false
        }
        if dict["custom"] == nil {
            dict["custom"] = [String: Any]()
        }
        if type == "notification.mark_read" {
            let user = dict["user"] as? [String: Any]
            if dict["total_unread_count"] == nil {
                dict["total_unread_count"] = user?["total_unread_count"] ?? 0
            }
            if dict["unread_channels"] == nil {
                dict["unread_channels"] = user?["unread_channels"] ?? 0
            }
            if dict["unread_count"] == nil {
                dict["unread_count"] = user?["unread_count"] ?? 0
            }
            if dict["unread_thread_messages"] == nil, let threads = user?["unread_threads"] {
                dict["unread_thread_messages"] = threads
            }
        }
        if let type,
           eventTypesRequiringChannel.contains(type),
           dict["channel"] == nil,
           let cid = dict["cid"] as? String,
           let parsed = parseCid(cid) {
            let createdAt = dict["created_at"] as? String ?? defaultDateString
            dict["channel"] = [
                "cid": cid,
                "id": parsed.id,
                "type": parsed.type,
                "created_at": createdAt,
                "updated_at": createdAt,
                "disabled": false,
                "frozen": false,
                "custom": [:]
            ]
        } else if var channel = dict["channel"] as? [String: Any] {
            normalizeChannel(channel: &channel, fallbackCreatedAt: dict["created_at"] as? String)
            dict["channel"] = channel
        }
        if let type,
           eventTypesRequiringMember.contains(type),
           dict["member"] == nil,
           let user = dict["user"] as? [String: Any],
           let userId = user["id"] as? String {
            let createdAt = dict["created_at"] as? String ?? defaultDateString
            dict["member"] = [
                "user_id": userId,
                "created_at": createdAt,
                "updated_at": createdAt,
                "banned": false,
                "shadow_banned": false,
                "channel_role": "",
                "notifications_muted": false,
                "custom": [:]
            ]
        }
    }

    private static func normalizeChannel(channel: inout [String: Any], fallbackCreatedAt: String?) {
        let createdAt = (channel["created_at"] as? String) ?? fallbackCreatedAt ?? defaultDateString
        if channel["created_at"] == nil { channel["created_at"] = createdAt }
        if channel["updated_at"] == nil { channel["updated_at"] = createdAt }
        if channel["disabled"] == nil { channel["disabled"] = false }
        if channel["frozen"] == nil { channel["frozen"] = false }
        if channel["custom"] == nil { channel["custom"] = [:] }
        if let config = channel["config"] as? [String: Any], config["created_at"] == nil {
            channel.removeValue(forKey: "config")
        }
        if let members = channel["members"] as? [[String: Any]] {
            channel["members"] = members.map { member -> [String: Any] in
                var normalized = member
                normalizeMember(member: &normalized, fallbackCreatedAt: createdAt)
                return normalized
            }
        }
    }

    private static func normalizeMember(member: inout [String: Any], fallbackCreatedAt: String) {
        if member["created_at"] == nil { member["created_at"] = fallbackCreatedAt }
        if member["updated_at"] == nil { member["updated_at"] = fallbackCreatedAt }
        if member["banned"] == nil { member["banned"] = false }
        if member["shadow_banned"] == nil { member["shadow_banned"] = false }
        if member["channel_role"] == nil { member["channel_role"] = "" }
        if member["notifications_muted"] == nil { member["notifications_muted"] = false }
        if member["custom"] == nil { member["custom"] = [:] }
    }

    private static func parseCid(_ cid: String) -> (type: String, id: String)? {
        guard let colon = cid.firstIndex(of: ":") else { return nil }
        return (String(cid[..<colon]), String(cid[cid.index(after: colon)...]))
    }

    private static let eventTypesRequiringChannel: Set<String> = [
        "channel.created", "channel.deleted", "channel.hidden", "channel.truncated",
        "channel.updated", "channel.visible",
        "member.added", "member.removed", "member.updated",
        "notification.added_to_channel", "notification.channel_deleted",
        "notification.channel_truncated", "notification.invite_accepted",
        "notification.invited", "notification.invite_rejected",
        "notification.message_new", "notification.removed_from_channel",
        "notification.thread_message_new",
        "reaction.deleted", "reaction.new", "reaction.updated"
    ]

    private static let eventTypesRequiringMember: Set<String> = [
        "member.added", "member.removed", "member.updated",
        "notification.added_to_channel", "notification.invite_accepted",
        "notification.invited", "notification.invite_rejected",
        "notification.removed_from_channel"
    ]

    private static let defaultDateString = "2020-01-01T00:00:00Z"
}
