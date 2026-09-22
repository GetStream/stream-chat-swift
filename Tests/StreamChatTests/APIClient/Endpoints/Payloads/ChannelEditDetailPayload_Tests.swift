//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let filterTag: String = .unique

        // Create ChannelEditDetailPayload
        let payload = ChannelEditDetailPayload(
            cid: cid,
            name: name,
            imageURL: imageURL,
            team: team,
            members: [invite],
            invites: [invite],
            filterTags: [filterTag],
            extraData: [:]
        )

        let expectedData: [String: Any] = [
            "name": name,
            "image": imageURL.absoluteString,
            "team": team,
            "members": [invite],
            "invites": [invite],
            "filter_tags": [filterTag]
        ]

        let encodedJSON = try JSONEncoder.default.encode(payload)
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])

        // Assert ChannelEditDetailPayload encoded correctly
        AssertJSONEqual(encodedJSON, expectedJSON)
    }

    func test_cid() {
        // Create payload without id specified
        let payload1: ChannelEditDetailPayload = .init(
            type: .messaging,
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [.unique],
            invites: [],
            filterTags: [],
            extraData: [:]
        )

        // Assert there is no cid without an id
        XCTAssertNil(payload1.cid)

        // Create payload with id and type specified
        let cid: ChannelId = .unique
        let payload2: ChannelEditDetailPayload = .init(
            cid: cid,
            name: .unique,
            imageURL: .unique(),
            team: nil,
            members: [],
            invites: [],
            filterTags: [],
            extraData: [:]
        )

        // Assert type and id form the cid
        XCTAssertEqual(payload2.cid, cid)
    }
}
