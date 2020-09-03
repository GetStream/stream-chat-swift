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
    
    func test_channelId_encoding() throws {
        XCTAssertEqual(encode(channelId: try ChannelId(cid: "*")), "*")
        XCTAssertEqual(encode(channelId: ChannelId(type: .messaging, id: "123")), "messaging:123")
        XCTAssertEqual(encode(channelId: ChannelId(type: .custom("asd"), id: "123")), "asd:123")
    }

    func test_channelId_decoding() throws {
        XCTAssertEqual(decode(value: "*"), try! ChannelId(cid: "*"))
        XCTAssertEqual(decode(value: "messaging:123"), ChannelId(type: .messaging, id: "123"))
        XCTAssertEqual(decode(value: "asd:123"), ChannelId(type: .custom("asd"), id: "123"))
    }

    func test_channelId_edgeCases() throws {
        // Channel with empty string
        XCTAssertThrowsError(try ChannelId(cid: ""))
        
        // Channel with invalid cid format
        XCTAssertThrowsError(try ChannelId(cid: "asd123"))
        
        // Unknown channel type
        let channelId = ChannelId(type: .unknown, id: "")
        XCTAssertEqual(channelId.type, ChannelType.unknown)
        XCTAssertEqual(channelId.id, "*")
    }
    
    @available(iOS, deprecated: 12.0, message: "Remove this workaround when dropping iOS 12 support.")
    private func encode(channelId: ChannelId) -> String? {
        // We must encode it as a part of JSON because older iOS version don't support JSON fragments
        let key = String.unique
        guard
            let data = try? JSONEncoder.stream.encode([key: channelId]),
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else { return nil }
        
        return json[key] as? String
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
