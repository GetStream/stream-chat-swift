//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberResponse_Tests: XCTestCase {
    let memberJSON = XCTestCase.mockData(fromJSONFile: "Member")
    let memberRoleJSON = XCTestCase.mockData(fromJSONFile: "MemberRole")

    func test_memberJSON_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(ChannelMemberResponse.self, from: memberJSON)

        XCTAssertEqual(MemberRole(rawChannelValue: payload.channelRole), .owner)
        XCTAssertEqual(payload.createdAt, "2020-06-05T12:53:09.862721Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-05T12:53:09.862721Z".toDate())
        XCTAssertEqual(payload.banExpires, "2021-03-08T15:42:31.355923Z".toDate())
        XCTAssertEqual(payload.banned, true)
        XCTAssertEqual(payload.shadowBanned, true)
        XCTAssertEqual(payload.notificationsMuted, true)
        XCTAssertEqual(payload.custom["is_premium"], true)

        let user = try XCTUnwrap(payload.user)
        XCTAssertEqual(user.id, "broken-waterfall-5")
        XCTAssertEqual(user.banned, false)
        XCTAssertEqual(user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(user.lastActive, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(user.name, "Broken Waterfall")
        XCTAssertEqual(
            user.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(user.userRole, .user)
        XCTAssertEqual(user.online, true)
    }

    func test_memberJSON_channelRole_isCustomRole() throws {
        let payload = try JSONDecoder.default.decode(ChannelMemberResponse.self, from: memberRoleJSON)
        XCTAssertEqual(MemberRole(rawChannelValue: payload.channelRole), "custom_role")
    }
}
