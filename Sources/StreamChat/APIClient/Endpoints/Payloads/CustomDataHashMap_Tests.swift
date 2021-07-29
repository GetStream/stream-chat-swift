//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

protocol DecodableEntity: Decodable {
    var extraDataMap: CustomData { get }
}

extension MessagePayload: DecodableEntity {}
extension MessageReactionPayload: DecodableEntity {}
extension UserPayload: DecodableEntity {}
extension ChannelDetailPayload: DecodableEntity {}

class CustomDataHashMap: XCTestCase {
    func test_UserWebSocketPayloadEncodeWithCustomMap() throws {
        let extraDataMap: CustomData = ["how-many-roads": .integer(42)]
        let userInfo = UserInfo<NoExtraData>.init(id: "42", name: "tommaso", imageURL: nil, extraDataMap: extraDataMap)
        let payload = UserWebSocketPayload<NoExtraData>.init(userInfo: userInfo)
        let encoded = try! JSONEncoder.default.encode(payload)
        let jsonStr = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(jsonStr, "{\"id\":\"42\",\"image_url\":\"42\",\"name\":\"42\",\"how-many-roads\":42}")
    }

    func assertEmptyCustomData<T>(_ entity: T.Type, _ fileName: String) throws where T: DecodableEntity {
        let jsonData = XCTestCase.mockData(fromFile: fileName)
        let payload = try JSONDecoder.default.decode(entity.self, from: jsonData)
        XCTAssertEqual(payload.extraDataMap, .defaultValue)
    }

    func assertCustomData<T>(_ entity: T.Type, _ fileName: String) throws where T: DecodableEntity {
        let jsonData = XCTestCase.mockData(fromFile: fileName)
        let payload = try JSONDecoder.default.decode(entity.self, from: jsonData)
        
        XCTAssertEqual(payload.extraDataMap["secret_note"], .string("Anakin is Vader!"))
        XCTAssertEqual(payload.extraDataMap["good_movies_count"], .integer(3))
        XCTAssertEqual(payload.extraDataMap["awesome"], .bool(true))
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
    
    func test_channelDetailJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(ChannelDetailPayload<NoExtraData>.self, "ChannelPayload")
    }
    
    func test_channelDetailJSONDecodeWithCustomData() throws {
        try! assertCustomData(ChannelDetailPayload<NoExtraData>.self, "ChannelPayloadWithCustom")
    }

    func test_messageJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(MessagePayload<NoExtraData>.self, "MessagePayload")
    }
    
    func test_messageJSONDecodeWithCustomData() throws {
        try! assertCustomData(MessagePayload<NoExtraData>.self, "MessagePayloadWithCustom")
    }
    
    func test_messageReactionJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(MessageReactionPayload<NoExtraData>.self, "MessageReactionPayload")
    }
    
    func test_messageReactionJSONDecodeWithCustomData() throws {
        try! assertCustomData(MessageReactionPayload<NoExtraData>.self, "MessageReactionPayloadWithCustom")
    }

    func test_userJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(UserPayload<NoExtraData>.self, "UserPayload")
    }
    
    func test_userJSONDecodeWithCustomData() throws {
        try! assertCustomData(UserPayload<NoExtraData>.self, "UserPayloadWithCustom")
    }
    
    func test_currentUserJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(CurrentUserPayload<NoExtraData>.self, "CurrentUserPayload")
    }
    
    func test_currentUserJSONDecodeWithCustomData() throws {
        try! assertCustomData(CurrentUserPayload<NoExtraData>.self, "CurrentUserPayloadWithCustom")
    }
}
