//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelEditDetailPayload_Tests: XCTestCase {
    // Test ChannelEditDetailPayload encoded correctly
    func test_channelEditDetailPayload_encodedCorrectly() throws {
        let cid: ChannelId = .unique
        let name: String = .unique
        let imageURL: URL = .unique()
        let team: String = .unique
        let invite: UserId = .unique

        // Create ChannelEditDetailPayload
        let payload = ChannelEditDetailPayload(
            cid: cid,
            name: name,
            imageURL: imageURL,
            team: team,
            members: [invite],
            invites: [invite],
            extraData: [:]
        )

        let expectedData: [String: Any] = [
            "name": name,
            "image": imageURL.absoluteString,
            "team": team,
            "members": [invite],
            "invites": [invite]
        ]

        let encodedJSON = try JSONEncoder.default.encode(payload)
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])

        // Assert ChannelEditDetailPayload encoded correctly
        AssertJSONEqual(encodedJSON, expectedJSON)
    }

    func test_apiPath() {
        // Create payload without id specified
        let payload1: ChannelEditDetailPayload = .init(
            type: .messaging,
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [.unique],
            invites: [],
            extraData: [:]
        )

        // Assert only type is part of path
        XCTAssertEqual(payload1.apiPath, "\(payload1.type)")

        // Create payload with id and type specified
        let cid: ChannelId = .unique
        let payload2: ChannelEditDetailPayload = .init(
            cid: cid,
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [],
            invites: [],
            extraData: [:]
        )

        // Assert type and id are part of path
        XCTAssertEqual(payload2.apiPath, "\(payload2.type.rawValue)/\(payload2.id!)")
    }
}
