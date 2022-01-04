//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class ChannelId_Tests: XCTestCase {
    func test_channelId() {
        let channelId = try! ChannelId(cid: "messaging:123")
        XCTAssertEqual(channelId.rawValue, "messaging:123")
        XCTAssertEqual(channelId.type, ChannelType.messaging)
        XCTAssertEqual(channelId.id, "123")
    }
    
    func test_invalidChannelId() {
        // Channel with invalid character
        XCTAssertThrowsError(try ChannelId(cid: "*"))
        
        // Channel with empty string
        XCTAssertThrowsError(try ChannelId(cid: ""))
        
        // Channel with invalid cid format
        XCTAssertThrowsError(try ChannelId(cid: "asd123"))
        
        // Channel with invalid cid format
        XCTAssertThrowsError(try ChannelId(cid: "      :      "))
        
        // Channel with invalid cid format
        XCTAssertThrowsError(try ChannelId(cid: ":"))
    }
    
    func test_channelId_encoding() throws {
        let encoder = JSONEncoder.stream
        XCTAssertEqual(encoder.encodedString(try ChannelId(cid: "messaging:123")), "messaging:123")
        XCTAssertEqual(encoder.encodedString(ChannelId(type: .messaging, id: "123")), "messaging:123")
        XCTAssertEqual(encoder.encodedString(ChannelId(type: .custom("asd"), id: "123")), "asd:123")
    }

    func test_channelId_decoding() throws {
        XCTAssertNil(decode(value: "*"))
        XCTAssertEqual(decode(value: "messaging:123"), ChannelId(type: .messaging, id: "123"))
        XCTAssertEqual(decode(value: "asd:123"), ChannelId(type: .custom("asd"), id: "123"))
    }
    
    func test_apiPath() {
        let channelId = ChannelId.unique
        XCTAssertEqual(channelId.apiPath, channelId.type.rawValue + "/" + channelId.id)
    }
    
    @available(iOS, deprecated: 12.0, message: "Remove this workaround when dropping iOS 12 support.")
    private func decode(value: String) -> ChannelId? {
        // We must decode it as a part of JSON because older iOS version don't support JSON fragments
        let key = String.unique
        let jsonString = #"{ "\#(key)" : "\#(value)"}"#
        let data = jsonString.data(using: .utf8)!
        let serializedJSON = try? JSONDecoder.stream.decode([String: ChannelId].self, from: data)
        return serializedJSON?[key]
    }
}
