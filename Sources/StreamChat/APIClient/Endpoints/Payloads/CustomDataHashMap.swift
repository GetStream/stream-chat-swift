//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class CustomDataHashMap: XCTestCase {
    func test_UserWebSocketPayloadEncodeWithCustomMap() throws {
        let extraDataMap: CustomData = ["how-many-roads": .integer(42)]
        let userInfo = UserInfo<NoExtraData>.init(id: "42", name: "tommaso", imageURL: nil, extraDataMap: extraDataMap)
        let payload = UserWebSocketPayload<NoExtraData>.init(userInfo: userInfo)
        let encoded = try! JSONEncoder.default.encode(payload)
        let jsonStr = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(jsonStr, "{\"id\":\"42\",\"image_url\":\"42\",\"name\":\"42\",\"how-many-roads\":42}")
    }

    func test_messageJSONDecodeWithoutAnyCustomData() throws {
        let currentUserJSON = XCTestCase.mockData(fromFile: "MessagePayload")
        let payload = try JSONDecoder.default.decode(MessagePayload<NoExtraData>.self, from: currentUserJSON)
        
        print(payload.extraDataMap)
        XCTAssertEqual(payload.extraDataMap.count, 0)
    }
    
    func test_messageJSONDecodeWithCustomData() throws {
        let currentUserJSON = XCTestCase.mockData(fromFile: "MessagePayloadWithCustom")
        let payload = try JSONDecoder.default.decode(MessagePayload<NoExtraData>.self, from: currentUserJSON)
        
        XCTAssertEqual(payload.extraDataMap["secret_note"], .string("Anakin is Vader!"))
        XCTAssertEqual(payload.extraDataMap["good_movies_count"], .integer(3))
        XCTAssertEqual(payload.extraDataMap["awesome"], .bool(true))
    }
    
    func test_messageJSONDecodeWithNestedCustomData() throws {
        let currentUserJSON = XCTestCase.mockData(fromFile: "MessagePayloadWithCustom")
        let payload = try JSONDecoder.default.decode(MessagePayload<NoExtraData>.self, from: currentUserJSON)
        
        XCTAssertEqual(payload.extraDataMap["nested_stuff"], .dictionary(
            [
                "how_many_times": .integer(42), "small": .double(0.001),
                "colors": .array([
                    .string("blue"),
                    .string("yellow"),
                    .integer(42)
                ])
            ]
        ))
    }
    
    func test_messagePayloadToMessage() throws {
        let currentUserJSON = XCTestCase.mockData(fromFile: "MessagePayloadWithCustom")
        let payload = try JSONDecoder.default.decode(MessagePayload<NoExtraData>.self, from: currentUserJSON)
    }
}
