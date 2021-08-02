//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

protocol DecodableEntity: Decodable {
    var extraData: CustomData { get }
}

extension MessagePayload: DecodableEntity {}
extension MessageReactionPayload: DecodableEntity {}
extension UserPayload: DecodableEntity {}
extension ChannelDetailPayload: DecodableEntity {}

class CustomDataHashMap: XCTestCase {
    func test_UserWebSocketPayloadEncodeWithCustomMap() throws {
        let extraData: CustomData = ["how-many-roads": .integer(42)]
        let userInfo = UserInfo(id: "44", name: "tommaso", imageURL: nil, extraData: extraData)
        let payload = UserWebSocketPayload(userInfo: userInfo)
        let encoded = try! JSONEncoder.default.encode(payload)
        let jsonStr = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(jsonStr, "{\"id\":\"44\",\"name\":\"tommaso\",\"how-many-roads\":42}")
    }

    func assertEmptyCustomData<T>(_ entity: T.Type, _ fileName: String) throws where T: DecodableEntity {
        let jsonData = XCTestCase.mockData(fromFile: fileName)
        let payload = try JSONDecoder.default.decode(entity.self, from: jsonData)
        XCTAssertEqual(payload.extraData, .defaultValue)
    }

    func assertCustomData<T>(_ entity: T.Type, _ fileName: String) throws where T: DecodableEntity {
        let jsonData = XCTestCase.mockData(fromFile: fileName)
        let payload = try JSONDecoder.default.decode(entity.self, from: jsonData)
        
        XCTAssertEqual(payload.extraData["secret_note"], .string("Anakin is Vader!"))
        XCTAssertEqual(payload.extraData["good_movies_count"], .integer(3))
        XCTAssertEqual(payload.extraData["awesome"], .bool(true))
        XCTAssertEqual(payload.extraData["nested_stuff"], .dictionary(
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
        try! assertEmptyCustomData(ChannelDetailPayload.self, "ChannelPayload")
    }
    
    func test_channelDetailJSONDecodeWithCustomData() throws {
        try! assertCustomData(ChannelDetailPayload.self, "ChannelPayloadWithCustom")
    }

    func test_messageJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(MessagePayload.self, "MessagePayload")
    }
    
    func test_messageJSONDecodeWithCustomData() throws {
        try! assertCustomData(MessagePayload.self, "MessagePayloadWithCustom")
    }
    
    func test_messageReactionJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(MessageReactionPayload.self, "MessageReactionPayload")
    }
    
    func test_messageReactionJSONDecodeWithCustomData() throws {
        try! assertCustomData(MessageReactionPayload.self, "MessageReactionPayloadWithCustom")
    }

    func test_userJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(UserPayload.self, "UserPayload")
    }
    
    func test_userJSONDecodeWithCustomData() throws {
        try! assertCustomData(UserPayload.self, "UserPayloadWithCustom")
    }
    
    func test_currentUserJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(CurrentUserPayload.self, "CurrentUserPayload")
    }
    
    func test_currentUserJSONDecodeWithCustomData() throws {
        try! assertCustomData(CurrentUserPayload.self, "CurrentUserPayloadWithCustom")
    }
}
