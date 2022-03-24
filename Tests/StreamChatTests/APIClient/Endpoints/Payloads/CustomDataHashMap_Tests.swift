//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

protocol DecodableEntity: Decodable {
    var extraData: [String: RawJSON] { get }
}

extension MessagePayload: DecodableEntity {}
extension MessageReactionPayload: DecodableEntity {}
extension UserPayload: DecodableEntity {}
extension ChannelDetailPayload: DecodableEntity {}

class CustomDataHashMap_Tests: XCTestCase {
    func test_UserWebSocketPayloadEncodeWithCustomMap() throws {
        let extraData: [String: RawJSON] = ["how-many-roads": .number(42)]
        let imageURL = URL.unique()
        let userInfo = UserInfo(id: "44", name: "tommaso", imageURL: imageURL, extraData: extraData)
        let payload = UserWebSocketPayload(userInfo: userInfo)
        let encoded = try! JSONEncoder.default.encode(payload)
        let jsonStr = String(data: encoded, encoding: .utf8)
        let imageStr = imageURL.debugDescription.replacingOccurrences(of: "/", with: "\\/")
        XCTAssertEqual(jsonStr, "{\"id\":\"44\",\"name\":\"tommaso\",\"image\":\"\(imageStr)\",\"how-many-roads\":42}")
    }

    func assertEmptyCustomData<T>(_ entity: T.Type, _ fileName: String) throws where T: DecodableEntity {
        let jsonData = XCTestCase.mockData(fromFile: fileName)
        let payload = try JSONDecoder.default.decode(entity.self, from: jsonData)
        XCTAssertEqual(payload.extraData, [:])
    }

    func assertCustomData<T>(_ entity: T.Type, _ fileName: String) throws where T: DecodableEntity {
        let jsonData = XCTestCase.mockData(fromFile: fileName)
        let payload = try JSONDecoder.default.decode(entity.self, from: jsonData)
        
        XCTAssertEqual(payload.extraData["secret_note"], .string("Anakin is Vader!"))
        XCTAssertEqual(payload.extraData["good_movies_count"], .number(3))
        XCTAssertEqual(payload.extraData["awesome"], .bool(true))
        XCTAssertEqual(payload.extraData["nested_stuff"], .dictionary(
            [
                "how_many_times": .number(42), "small": .double(0.001),
                "colors": .array([
                    .string("blue"),
                    .string("yellow"),
                    .number(42)
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
