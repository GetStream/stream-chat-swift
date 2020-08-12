//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class ChannelId_Tests: XCTestCase {
    func test_channelId() {
        let channelId = try! ChannelId(cid: "messaging:123")
        XCTAssertEqual(channelId.rawValue, "messaging:123")
        XCTAssertEqual(channelId.type, ChannelType.messaging)
        XCTAssertEqual(channelId.id, "123")
        XCTAssertFalse(channelId.isAny)
    }
    
    func test_channelId_any() throws {
        var channelId = try! ChannelId(cid: "*")
        XCTAssertEqual(channelId.rawValue, "unknown:*")
        XCTAssertTrue(channelId.isAny)
        
        channelId = ChannelId(type: .unknown, id: "*")
        XCTAssertEqual(channelId.rawValue, "unknown:*")
        XCTAssertTrue(channelId.isAny)
    }
    
    func test_channelId_coding() throws {
        try encode(channelId: try ChannelId(cid: "*"), value: "\"*\"")
        try decode(channelId: try ChannelId(cid: "*"), value: "\"*\"")
        try encode(channelId: ChannelId(type: .messaging, id: "123"), value: "\"messaging:123\"")
        try decode(channelId: ChannelId(type: .messaging, id: "123"), value: "\"messaging:123\"")
        try encode(channelId: ChannelId(type: .custom("asd"), id: "123"), value: "\"asd:123\"")
        try decode(channelId: ChannelId(type: .custom("asd"), id: "123"), value: "\"asd:123\"")
    }
    
    func test_channelId_edgeCases() throws {
        XCTAssertThrowsError(try ChannelId(cid: ""))
        XCTAssertThrowsError(try ChannelId(cid: "asd123"))
        
        let channelId = ChannelId(type: .unknown, id: "")
        XCTAssertEqual(channelId.type, ChannelType.unknown)
        XCTAssertEqual(channelId.id, "*")
        try encode(channelId: channelId, value: "\"*\"")
        try decode(channelId: channelId, value: "\"*\"")
    }
    
    private func encode(channelId: ChannelId, value: String) throws {
        let data = try JSONEncoder.stream.encode(channelId)
        let string = String(data: data, encoding: .utf8)
        XCTAssertEqual(string, value)
    }
    
    private func decode(channelId: ChannelId, value: String) throws {
        let data = value.data(using: .utf8)!
        let decodedChannelId = try JSONDecoder.stream.decode(ChannelId.self, from: data)
        XCTAssertEqual(channelId, decodedChannelId)
    }
}
