//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CurrentUserPayload_Tests: XCTestCase {
    let currentUserJSON = XCTestCase.mockData(fromJSONFile: "CurrentUser")

    func test_currentUserJSON_customRoleIsDecodedCorrectly() throws {
        let json = XCTestCase.mockData(fromJSONFile: "CurrentUserCustomRole")
        let payload = try JSONDecoder.default.decode(OwnUser.self, from: json)
        XCTAssertEqual(payload.role, "banana-master")
    }

    func test_currentUserJSON_isDecodedCorrectly() throws {
        let payload = try JSONDecoder.default.decode(OwnUser.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.banned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActive, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
//        XCTAssertEqual(payload.name, "Broken Waterfall")
        XCTAssertEqual(payload.teams?.count, 3)
//        XCTAssertEqual(
//            payload.imageURL,
//            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
//        )
        XCTAssertEqual(payload.role, "user")
        XCTAssertEqual(payload.online, true)
        XCTAssertEqual(payload.devices.map(\.id), [
            "cjqZTUHaQIykfH-706Xefw:APA91bF0Ig0gi4ro6w3iPfmE8",
            "e25wfsxcnyA:APA91bFgZR_hfd6GvR42OqCUgIhvpBajjxw7"
        ])
        XCTAssertEqual(payload.mutes.compactMap(\.?.user?.id), ["broken-waterfall-5"])
        XCTAssertEqual(payload.custom, ["secret_note": .string("Anaking is Vader!")])
        XCTAssertEqual(payload.channelMutes.count, 1)
        XCTAssertEqual(payload.channelMutes[0]?.user?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.channelMutes[0]?.channel?.cid, "messaging:B1DFF9C5-E6A6-4BFA-9375-DC5E8C6852FF")
        XCTAssertEqual(payload.channelMutes[0]?.createdAt, "2021-03-22T10:23:52.516225Z".toDate())
        XCTAssertEqual(payload.channelMutes[0]?.updatedAt, "2021-04-22T10:23:52.516225Z".toDate())
        XCTAssertEqual(payload.invisible, true)
    }
}
