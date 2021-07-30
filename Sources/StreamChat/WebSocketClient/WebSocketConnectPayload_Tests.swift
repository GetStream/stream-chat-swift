//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class WebSocketConnectPayload_Tests: XCTestCase {
    func testEncodeWebSocketConnectPayload() throws {
        let custom: CustomData = [
            "color": .string("blue")
        ]
        let payload =
            WebSocketConnectPayload(
                userInfo: .init(
                    id: "tommaso",
                    name: "tommaso",
                    imageURL: .init(string: "https://path/to/image"),
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
                "image_url": "https://path/to/image",
                "color": "blue"
            ]
        ]
        AssertJSONEqual(serialized, expected)
    }
    
    func testEncodeWebSocketConnectPayloadNoImage() throws {
        let custom: CustomData = [
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
