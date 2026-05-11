//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelInput_Tests: XCTestCase {
    // Test ChannelInput encoded correctly
    func test_channelEditDetailPayload_encodedCorrectly() throws {
        let cid: ChannelId = .unique
        let name: String = .unique
        let imageURL: URL = .unique()
        let team: String = .unique
        let invite: UserId = .unique
        let filterTag: String = .unique

        // Create ChannelInput
        let payload = ChannelInput(
            name: name,
            imageURL: imageURL,
            team: team,
            members: [invite],
            invites: [invite],
            filterTags: [filterTag],
            extraData: [:]
        )

        let expectedData: [String: Any] = [
            "custom": [
                "name": name,
                "image": imageURL.absoluteString
            ],
            "team": team,
            "members": [["user_id": invite]],
            "invites": [["user_id": invite]],
            "filter_tags": [filterTag]
        ]

        let encodedJSON = try JSONEncoder.default.encode(payload)
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])

        // Assert ChannelInput encoded correctly
        AssertJSONEqual(encodedJSON, expectedJSON)
    }

    func test_channelQueryCarriesAPIPath() {
        // Create payload without id specified
        let payload1: ChannelInput = .init(
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [.unique],
            invites: [],
            filterTags: [],
            extraData: [:]
        )

        // Assert only type is part of path
        XCTAssertEqual(ChannelQuery(id: nil, type: .messaging, channelPayload: payload1).apiPath, "messaging")

        // Create payload with id and type specified
        let cid: ChannelId = .unique
        let payload2: ChannelInput = .init(
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [],
            invites: [],
            filterTags: [],
            extraData: [:]
        )

        // Assert type and id are part of path
        XCTAssertEqual(ChannelQuery(id: cid.id, type: cid.type, channelPayload: payload2).apiPath, cid.apiPath)
    }
}
