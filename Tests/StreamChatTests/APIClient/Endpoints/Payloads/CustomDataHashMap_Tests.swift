//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CustomDataHashMap_Tests: XCTestCase {
    func test_UserWebSocketPayloadEncodeWithCustomMap() throws {
        let extraData: [String: RawJSON] = ["how-many-roads": .number(42)]
        let imageURL = URL.unique()
        let userInfo = UserInfo(
            id: "44",
            name: "tommaso",
            imageURL: imageURL,
            isInvisible: false,
            language: .english,
            extraData: extraData
        )
        let payload = UserWebSocketPayload(userInfo: userInfo)
        let encoded = try! JSONEncoder.default.encode(payload)
        AssertJSONEqual(encoded, [
            "language": "en",
            "id": "44",
            "invisible": false,
            "name": "tommaso",
            "image": imageURL.absoluteString,
            "how-many-roads": 42
        ])
    }

    func test_channelDetailJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(ChannelResponse.self, "ChannelPayload")
    }

    func test_channelDetailJSONDecodeWithCustomData() throws {
        try! assertCustomData(ChannelResponse.self, "ChannelPayloadWithCustom")
    }

    func test_messageJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(MessageResponse.self, "MessageResponse")
    }

    func test_messageJSONDecodeWithCustomData() throws {
        try! assertCustomData(MessageResponse.self, "MessageResponseWithCustom")
    }

    func test_messageReactionJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(ReactionResponse.self, "MessageReactionPayload")
    }

    func test_messageReactionJSONDecodeWithCustomData() throws {
        try! assertCustomData(ReactionResponse.self, "MessageReactionPayloadWithCustom")
    }

    func test_userJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(UserResponse.self, "UserResponse")
    }

    func test_userJSONDecodeWithCustomData() throws {
        try! assertCustomData(UserResponse.self, "UserResponseWithCustom")
    }

    func test_currentUserJSONDecodeWithoutAnyCustomData() throws {
        try! assertEmptyCustomData(OwnUserResponse.self, "OwnUserResponse")
    }

    func test_currentUserJSONDecodeWithCustomData() throws {
        try! assertCustomData(OwnUserResponse.self, "OwnUserResponseWithCustom")
    }
}

// MARK: Test helpers

extension CustomDataHashMap_Tests {
    func assertEmptyCustomData<T>(_ entity: T.Type, _ fileName: String) throws where T: DecodableEntity {
        let jsonData = XCTestCase.mockData(fromJSONFile: fileName)
        let payload = try JSONDecoder.default.decode(entity.self, from: jsonData)
        XCTAssertEqual(payload.extraData, [:])
    }

    func assertCustomData<T>(_ entity: T.Type, _ fileName: String) throws where T: DecodableEntity {
        let jsonData = XCTestCase.mockData(fromJSONFile: fileName)
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
}
