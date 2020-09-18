//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class ChannelEditDetailPayload_Tests: XCTestCase {
    // Test ChannelEditDetailPayload encoded correctly
    func test_channelEditDetailPayload_encodedCorrectly() throws {
        let cid: ChannelId = .unique
        let name: String = .unique
        let imageURL: URL = .unique()
        let team: String = .unique
        let invite: UserId = .unique
        let extraData: NameAndImageExtraData = .init(name: name, imageURL: imageURL)

        // Create ChannelEditDetailPayload
        let payload = ChannelEditDetailPayload<DefaultExtraData>(
            cid: cid,
            team: team,
            members: [invite],
            invites: [invite],
            extraData: extraData
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
}
