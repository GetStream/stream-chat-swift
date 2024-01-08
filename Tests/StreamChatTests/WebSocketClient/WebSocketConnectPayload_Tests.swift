//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class WebSocketConnectPayload_Tests: XCTestCase {
    func test_encodesWebSocket_whenCorrectConnectPayloadIsPassed() throws {
        let custom: [String: RawJSON] = [
            "color": .string("blue")
        ]

        let imageURL: URL? = URL(string: "https://path/to/image")
        let payload =
            WebSocketConnectPayload(
                userInfo: .init(
                    id: "tommaso",
                    name: "tommaso",
                    imageURL: imageURL,
                    isInvisible: true,
                    extraData: custom
                )
            )

        let serialized = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "user_id": payload.userDetails.id,
            "server_determines_connection_id": true,
            "user_details": [
                "id": payload.userDetails.id,
                "name": payload.userDetails.name!,
                "image": "https://path/to/image",
                "color": "blue",
                "invisible": true
            ] as [String: Any]
        ]
        AssertJSONEqual(serialized, expected)
    }

    func test_encodesWebSocket_whenUserInfoWithDefaultValues() throws {
        let payload = WebSocketConnectPayload(userInfo: .init(id: "tommaso"))
        let serialized = try JSONEncoder.stream.encode(payload)

        /// By default all data in UserInfo should be `nil` besides the ID which is required.
        let expected: [String: Any] = [
            "user_id": payload.userDetails.id,
            "server_determines_connection_id": true,
            "user_details": [
                "id": payload.userDetails.id
            ] as [String: Any]
        ]
        AssertJSONEqual(serialized, expected)
    }

    func test_EncodesWebSocket_whenConnectPayloadHasNoImage() throws {
        let custom: [String: RawJSON] = [
            "color": .string("blue")
        ]
        let payload = WebSocketConnectPayload(userInfo: .init(id: "tommaso", name: "tommaso", imageURL: nil, extraData: custom))

        let serialized = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "user_id": payload.userDetails.id,
            "server_determines_connection_id": true,
            "user_details": [
                "id": payload.userDetails.id,
                "name": payload.userDetails.name!,
                "color": "blue"
            ] as [String: Any]
        ]
        AssertJSONEqual(serialized, expected)
    }

    func test_encodesWebSocket_whenConnectPayloadHasNoInvisible() throws {
        let custom: [String: RawJSON] = [
            "color": .string("blue")
        ]
        let payload = WebSocketConnectPayload(userInfo: .init(
            id: "tommaso",
            name: "tommaso",
            imageURL: nil,
            isInvisible: nil,
            extraData: custom
        ))

        let serialized = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "user_id": payload.userDetails.id,
            "server_determines_connection_id": true,
            "user_details": [
                "id": payload.userDetails.id,
                "name": payload.userDetails.name!,
                "color": "blue"
            ] as [String: Any]
        ]
        AssertJSONEqual(serialized, expected)
    }
}
