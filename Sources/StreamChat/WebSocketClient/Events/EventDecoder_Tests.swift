//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class EventDecoder_Tests: XCTestCase {
    let eventDecoder = EventDecoder()
    
    // MARK: System events
    
    func test_decode_whenValidSystemEventPayloadComes_returnsDecodedSystemEvent() throws {
        // Load valid system event JSON.
        let json = XCTestCase.mockData(fromFile: "NotificationAddedToChannel")
        
        // Decode an event.
        let event = try eventDecoder.decode(from: json)
        
        // Assert system event is decoded.
        XCTAssertTrue(event is NotificationAddedToChannelEventDTO)
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
    
    // MARK: Custom events
    
    func test_decode_whenValidCustomEventPayloadComes_returnsUnkownEvent() throws {
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
            "idea" : "\(ideaPayload.idea)"
        }
        """.data(using: .utf8)!
        
        // Assert event is decoded.
        let event = try eventDecoder.decode(from: json)
        // Assert `UnknownEvent` event with expected payload is decoded
        let unkownEvent = try XCTUnwrap(event as? UnknownEvent)
        
        // Assert event has correct fields.
        XCTAssertEqual(unkownEvent.cid, cid)
        XCTAssertEqual(unkownEvent.userId, userId)
        XCTAssertEqual(unkownEvent.createdAt, createdAt.toDate())
        XCTAssertEqual(unkownEvent.payload(ofType: IdeaEventPayload.self), ideaPayload)
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
            XCTAssertTrue(error is DecodingError)
        }
    }
}
