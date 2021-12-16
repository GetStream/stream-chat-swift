//
//  UnknownUserEvent_Tests.swift
//  StreamChatTests
//
//  Created by Boris Bielik on 16/12/2021.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class UnknownUserEvent_Tests: XCTestCase {
    func test_unkownEvent_decoding() throws {
        // Create event fields
        let userId: UserId = .unique
        let ideaPayload: IdeaEventPayload = .unique
        let createdAt: String = "2020-07-16T15:38:10.289007Z"

        // Create event JSON
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
            "created_at" : "\(createdAt)",
            "type" : "\(IdeaEventPayload.eventType.rawValue)",
            "idea" : "\(ideaPayload.idea)"
        }
        """.data(using: .utf8)!
    
        // Decode unkown event from JSON.
        let unknownEvent = try JSONDecoder.default.decode(UnknownUserEvent.self, from: json)
        let payload = try JSONDecoder.default.decode([String: RawJSON].self, from: json)
        
        // Assert all fields are correct.
        XCTAssertEqual(unknownEvent.userId, userId)
        XCTAssertEqual(unknownEvent.createdAt, createdAt.toDate())
        XCTAssertEqual(unknownEvent.type, IdeaEventPayload.eventType)
        XCTAssertEqual(unknownEvent.payload, payload)
    }
    
    func test_whenAllFieldsArePresentedAndTypeMatches_customPayloadIsDecoded() throws {
        // Create custom event payload.
        let payload = IdeaEventPayload.unique
        
        // Create event with `IdeaEventPayload` payload.
        let unkownEvent = UnknownUserEvent(
            type: IdeaEventPayload.eventType,
            userId: .unique,
            createdAt: .unique,
            payload: ["idea": .string(payload.idea)]
        )
        
        // Assert payload is decoded.
        XCTAssertEqual(unkownEvent.payload(ofType: IdeaEventPayload.self), payload)
    }
    
    func test_whenFieldsAreMissing_customPayloadIsNotDecoded() throws {
        // Create event with `IdeaEventPayload` fields missing.
        let unkownEvent = UnknownUserEvent(
            type: IdeaEventPayload.eventType,
            userId: .unique,
            createdAt: .unique,
            payload: [:]
        )
        
        // Assert payload is not decoded because fields are missing.
        XCTAssertNil(unkownEvent.payload(ofType: IdeaEventPayload.self))
    }
    
    func test_whenAllFieldsArePresentedButTypeDoesNotMatch_customPayloadIsNotDecoded() throws {
        // Create random event type.
        let randomEventType = EventType(rawValue: .unique)
        
        // Create event with `IdeaEventPayload` fields missing.
        let unkownEvent = UnknownUserEvent(
            type: randomEventType,
            userId: .unique,
            createdAt: .unique,
            payload: ["idea": .string(.unique)]
        )
        
        // Assert payload is not decoded because the type does not match.
        XCTAssertNil(unkownEvent.payload(ofType: IdeaEventPayload.self))
    }
}
