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
    
    func test_pathParameters() {
        // Create payload without id specified
        let payload1: ChannelEditDetailPayload<DefaultExtraData> = .init(
            type: .messaging,
            team: nil,
            members: [.unique],
            invites: [],
            extraData: .defaultValue
        )
        
        // Assert only type is part of path
        XCTAssertEqual(payload1.pathParameters, "\(payload1.type)")
        
        // Create payload with id and type specified
        let cid: ChannelId = .unique
        let payload2: ChannelEditDetailPayload<DefaultExtraData> = .init(
            cid: cid,
            team: nil,
            members: [],
            invites: [],
            extraData: .defaultValue
        )
        
        // Assert type and id are part of path
        XCTAssertEqual(payload2.pathParameters, "\(payload2.type)/\(payload2.id!)")
    }
}
