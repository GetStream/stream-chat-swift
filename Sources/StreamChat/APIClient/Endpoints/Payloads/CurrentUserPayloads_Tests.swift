//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

class CurrentUserPayload_Tests: XCTestCase {
    let currentUserJSON = XCTestCase.mockData(fromFile: "CurrentUser")
    
    func test_currentUserJSON_customRoleIsDecodedCorrectly() throws {
        let json = XCTestCase.mockData(fromFile: "CurrentUserCustomRole")
        let payload = try JSONDecoder.default.decode(CurrentUserPayload.self, from: json)
        XCTAssertEqual(payload.role, .custom("banana-master"))
    }

    func test_currentUserJSON_isDecodedCorrectly() throws {
        let payload = try JSONDecoder.default.decode(CurrentUserPayload.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.name, "Broken Waterfall")
        XCTAssertEqual(payload.teams.count, 3)
        XCTAssertEqual(
            payload.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.devices.map(\.id), [
            "cjqZTUHaQIykfH-706Xefw:APA91bF0Ig0gi4ro6w3iPfmE8",
            "e25wfsxcnyA:APA91bFgZR_hfd6GvR42OqCUgIhvpBajjxw7"
        ])
        XCTAssertEqual(payload.mutedUsers.map(\.mutedUser.id), ["dawn-grass-7"])
        XCTAssertEqual(payload.extraData, ["secret_note": .string("Anaking is Vader!")])
        XCTAssertEqual(payload.mutedChannels.count, 1)
        XCTAssertEqual(payload.mutedChannels[0].user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.mutedChannels[0].mutedChannel.cid.rawValue, "messaging:B1DFF9C5-E6A6-4BFA-9375-DC5E8C6852FF")
        XCTAssertEqual(payload.mutedChannels[0].createdAt, "2021-03-22T10:23:52.516225Z".toDate())
        XCTAssertEqual(payload.mutedChannels[0].updatedAt, "2021-03-22T10:23:52.516225Z".toDate())
    }
}
