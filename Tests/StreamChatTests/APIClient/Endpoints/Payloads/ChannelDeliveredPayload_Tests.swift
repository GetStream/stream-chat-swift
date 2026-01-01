//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelDeliveredPayload_Tests: XCTestCase {
    func test_deliveredMessagePayload_encodesCorrectly() throws {
        // GIVEN
        let cid = ChannelId(type: .messaging, id: "test-channel")
        let messageId = MessageId.unique
        let payload = DeliveredMessagePayload(cid: cid, id: messageId)
        
        // WHEN
        let encoded = try JSONEncoder.stream.encode(payload)
        let decoded = try JSONDecoder.stream.decode([String: String].self, from: encoded)
        
        // THEN
        XCTAssertEqual(decoded["cid"], cid.rawValue)
        XCTAssertEqual(decoded["id"], messageId)
    }
    
    func test_channelDeliveredRequestPayload_encodesCorrectly() throws {
        // GIVEN
        let cid1 = ChannelId(type: .messaging, id: "test-channel-1")
        let messageId1 = MessageId.unique
        let deliveredMessage1 = DeliveredMessagePayload(cid: cid1, id: messageId1)
        
        let cid2 = ChannelId(type: .livestream, id: "test-channel-2")
        let messageId2 = MessageId.unique
        let deliveredMessage2 = DeliveredMessagePayload(cid: cid2, id: messageId2)
        
        let payload = ChannelDeliveredRequestPayload(latestDeliveredMessages: [deliveredMessage1, deliveredMessage2])
        
        // WHEN
        let encoded = try JSONEncoder.stream.encode(payload)
        let decoded = try JSONDecoder.stream.decode([String: [[String: String]]].self, from: encoded)
        
        // THEN
        let latestDeliveredMessages = decoded["latest_delivered_messages"]!
        XCTAssertEqual(latestDeliveredMessages.count, 2)
        
        XCTAssertEqual(latestDeliveredMessages[0]["cid"], cid1.rawValue)
        XCTAssertEqual(latestDeliveredMessages[0]["id"], messageId1)
        
        XCTAssertEqual(latestDeliveredMessages[1]["cid"], cid2.rawValue)
        XCTAssertEqual(latestDeliveredMessages[1]["id"], messageId2)
    }
}
