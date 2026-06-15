//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class OwnUserResponse_Tests: XCTestCase {
    let currentUserJSON = XCTestCase.mockData(fromJSONFile: "CurrentUser")

    func test_currentUserJSON_customRoleIsDecodedCorrectly() throws {
        let json = XCTestCase.mockData(fromJSONFile: "CurrentUserCustomRole")
        let payload = try JSONDecoder.default.decode(OwnUserResponse.self, from: json)
        XCTAssertEqual(payload.asUserResponse().userRole, UserRole("banana-master"))
    }

    func test_currentUserJSON_isDecodedCorrectly() throws {
        let payload = try JSONDecoder.default.decode(OwnUserResponse.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.banned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActive, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.name, "Broken Waterfall")
        XCTAssertEqual(payload.teams?.count, 3)
        XCTAssertEqual(
            payload.asUserResponse().imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.asUserResponse().userRole, .user)
        XCTAssertEqual(payload.online, true)
        XCTAssertEqual(payload.devices.map(\.id), [
            "cjqZTUHaQIykfH-706Xefw:APA91bF0Ig0gi4ro6w3iPfmE8",
            "e25wfsxcnyA:APA91bFgZR_hfd6GvR42OqCUgIhvpBajjxw7"
        ])
        XCTAssertEqual(payload.mutes.compactMap(\.target?.id), ["dawn-grass-7"])
        XCTAssertEqual(payload.custom, ["secret_note": .string("Anaking is Vader!")])
        XCTAssertEqual(payload.channelMutes.count, 1)
        XCTAssertEqual(payload.channelMutes[0].user?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.channelMutes[0].channel?.cid, "messaging:B1DFF9C5-E6A6-4BFA-9375-DC5E8C6852FF")
        XCTAssertEqual(payload.channelMutes[0].createdAt, "2021-03-22T10:23:52.516225Z".toDate())
        XCTAssertEqual(payload.channelMutes[0].updatedAt, "2021-04-22T10:23:52.516225Z".toDate())
        XCTAssertEqual(payload.invisible, true)
        XCTAssertNotNil(payload.pushPreferences)
        XCTAssertEqual(payload.pushPreferences?.chatLevel, "mentions")
        XCTAssertEqual(payload.pushPreferences?.disabledUntil, "2024-12-31T23:59:59.999Z".toDate())
    }

    func test_ownUserPayload_asUserResponse_preservesUserFields() {
        let payload = OwnUserResponse.dummy(
            userId: .unique,
            name: "Leia",
            imageURL: URL(string: "https://example.com/leia.png"),
            isOnline: true,
            isInvisible: false,
            isBanned: false,
            role: .admin,
            teamsRole: ["ios": .admin],
            extraData: ["rank": .string("general")],
            teams: ["rebels"],
            language: "en"
        )

        let converted = payload.asUserResponse()

        XCTAssertEqual(converted.id, payload.id)
        XCTAssertEqual(converted.name, payload.name)
        XCTAssertEqual(converted.image, payload.image)
        XCTAssertEqual(converted.role, payload.role)
        XCTAssertEqual(converted.teamsRole, payload.teamsRole)
        XCTAssertEqual(converted.custom, payload.custom)
        XCTAssertEqual(converted.teams, payload.teams)
        XCTAssertEqual(converted.language, payload.language)
        XCTAssertEqual(converted.online, payload.online)
        XCTAssertEqual(converted.banned, payload.banned)
    }
}
