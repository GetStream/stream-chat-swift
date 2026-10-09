//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelQuery_Tests: XCTestCase {
    // Test ChannelQuery encoded correctly
    func test_channelQuery_encodedCorrectly() throws {
        let cid: ChannelId = .unique
        let paginationParameter: PaginationParameter = .lessThan("testId")
        let membersLimit = 10
        let watchersLimit = 10

        // Create ChannelQuery
        let query = ChannelQuery(
            cid: cid,
            paginationParameter: paginationParameter,
            membersLimit: membersLimit,
            watchersLimit: watchersLimit
        )

        let expectedData: [String: Any] = [
            "presence": true,
            "watch": true,
            "state": true,
            "messages": ["limit": 25, "id_lt": "testId"] as [String: Any],
            "members": ["limit": 10],
            "watchers": ["limit": 10]
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        // Assert ChannelQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    func test_endpoint_backendDefaultWatchersLimit_omitsLimit() throws {
        let query = ChannelQuery(cid: .unique, watchersLimit: .backendDefaultPageSize)

        let request = try XCTUnwrap(query.endpoint.body as? ChannelGetOrCreateRequest)
        let json = try JSONEncoder.default.encode(request)

        AssertJSONEqual(json, [
            "messages": ["limit": 25],
            "presence": true,
            "state": true,
            "watch": true,
            "watchers": [:]
        ])
    }

    func test_endpoint_channelInput_isSentAsData() throws {
        let cid: ChannelId = .unique
        let member: UserId = .unique
        let invite: UserId = .unique
        let channelInput = ChannelInput(
            name: "Team",
            imageURL: URL(string: "https://getstream.io/image.jpg"),
            team: "red",
            members: [member],
            invites: [invite],
            filterTags: ["vip"],
            extraData: ["color": .string("blue")]
        )
        let query = ChannelQuery(type: cid.type, id: cid.id, channelInput: channelInput)

        XCTAssertEqual(query.cid, cid)
        let body = try AnyEndpoint(query.endpoint).bodyAsDictionary()
        let data = try XCTUnwrap(body["data"] as? [String: Any])
        XCTAssertEqual(data["custom"] as? [String: String], [
            "name": "Team",
            "image": "https://getstream.io/image.jpg",
            "color": "blue"
        ])
        XCTAssertEqual(data["team"] as? String, "red")
        XCTAssertEqual(data["filter_tags"] as? [String], ["vip"])
        let invites = try XCTUnwrap(data["invites"] as? [[String: Any]])
        XCTAssertEqual(invites.compactMap { $0["user_id"] as? String }, [invite])
        let members = try XCTUnwrap(data["members"] as? [[String: Any]])
        XCTAssertEqual(Set(members.compactMap { $0["user_id"] as? String }), [member, invite])
    }

    func test_cid_whenIdIsNil_isNil() {
        let query = ChannelQuery(type: .messaging, id: nil, channelInput: ChannelInput())

        XCTAssertNil(query.cid)
        XCTAssertEqual(query.type, .messaging)
    }
}
