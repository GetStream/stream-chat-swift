//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class WebSocketConnectPayload_Tests: XCTestCase {
    func testEncodeWebSocketConnectPayload() throws {
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
                "color": "blue"
            ]
        ]
        AssertJSONEqual(serialized, expected)
    }
    
    func testEncodeWebSocketConnectPayloadNoImage() throws {
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
            ]
        ]
        AssertJSONEqual(serialized, expected)
    }
}
