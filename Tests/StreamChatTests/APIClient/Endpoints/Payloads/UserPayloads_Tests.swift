//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserPayload_Tests: XCTestCase {
    let currentUserJSON = XCTestCase.mockData(fromJSONFile: "CurrentUser")
    let otherUserJSON = XCTestCase.mockData(fromJSONFile: "OtherUser")

    func test_currentUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserResponse.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.banned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActive, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertNil(payload.deactivatedAt)
        XCTAssertEqual(payload.custom["name"]?.stringValue, "Broken Waterfall")
        XCTAssertEqual(
            payload.custom["image"]?.stringValue,
            "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall"
        )
        XCTAssertEqual(payload.role, UserRole.user.rawValue)
        XCTAssertEqual(payload.online, true)
        XCTAssertEqual(payload.teams?.count, 3)
        XCTAssertEqual(payload.language, "pt")
    }

    func test_currentUserJSON_isSerialized_withCustomExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserResponse.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.banned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActive, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertNil(payload.deactivatedAt)
        XCTAssertEqual(payload.role, UserRole.user.rawValue)
        XCTAssertEqual(payload.online, true)
        XCTAssertEqual(payload.teams?.count, 3)
        XCTAssertEqual(payload.language, "pt")

        XCTAssertEqual(payload.custom, ["secret_note": .string("Anaking is Vader!")])
    }

    func test_otherUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserResponse.self, from: otherUserJSON)
        XCTAssertEqual(payload.id, "bitter-cloud-0")
        XCTAssertEqual(payload.banned, true)
        XCTAssertEqual(payload.online, true)
        XCTAssertEqual(payload.custom["name"]?.stringValue, "Bitter cloud")
        XCTAssertEqual(payload.createdAt, "2020-06-09T18:33:04.070518Z".toDate())
        XCTAssertEqual(payload.lastActive, "2020-06-09T18:33:04.075114Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-09T18:33:04.078929Z".toDate())
        XCTAssertNil(payload.deactivatedAt)
        XCTAssertEqual(
            payload.custom["image"]?.stringValue,
            "https://getstream.io/random_png/?name=Bitter+cloud"
        )
        XCTAssertEqual(payload.teams?.count, 3)
        XCTAssertEqual(payload.language, "pt")
        XCTAssertEqual(payload.role, UserRole.guest.rawValue)
        XCTAssertEqual(payload.online, true)
    }

    func test_deactivatedUserJSON_isSerialized() throws {
        let deactivatedUserJSON = XCTestCase.mockData(fromJSONFile: "DeactivatedUser")
        let payload = try JSONDecoder.default.decode(UserResponse.self, from: deactivatedUserJSON)
        XCTAssertEqual(payload.id, "deactivated-5")
        XCTAssertEqual(payload.banned, false)
        XCTAssertEqual(payload.online, true)
        XCTAssertEqual(payload.custom["name"]?.stringValue, "Deactivated Waterfall")
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActive, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.deactivatedAt, "2017-05-09T13:32:30.628Z".toDate())
        XCTAssertEqual(
            payload.custom["image"]?.stringValue,
            "https://getstream.io/random_svg/?id=deactivated-waterfall-5&amp;name=Deactivated+waterfall"
        )
        XCTAssertEqual(payload.teams?.count, 3)
        XCTAssertEqual(payload.role, UserRole.user.rawValue)
        XCTAssertEqual(payload.online, true)
    }
}

final class UserUpdateResponse_Tests: XCTestCase {
    func test_currentUserUpdateResponseJSON_isSerialized() throws {
        let currentUserUpdateResponseJSON = XCTestCase.mockData(fromJSONFile: "UserUpdateResponse")
        let payload = try JSONDecoder.default.decode(
            UpdateUsersResponse.self, from: currentUserUpdateResponseJSON
        )
        let user = payload.users.first!.value
        XCTAssertEqual(user.id, "luke_skywalker")
        XCTAssertEqual(user.role, UserRole.user.rawValue)
        XCTAssertEqual(user.createdAt, "2020-12-07T11:36:47.059906Z".toDate())
        XCTAssertEqual(user.updatedAt, "2021-01-11T10:36:24.488391Z".toDate())
        XCTAssertEqual(user.lastActive, "2021-01-08T19:16:54.380686Z".toDate())
        XCTAssertEqual(user.banned, false)
        XCTAssertEqual(user.online, false)
        XCTAssertEqual(user.custom?["name"]?.stringValue, "Luke")
        let expectedImage = "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg"
        XCTAssertEqual(user.custom?["image"]?.stringValue, expectedImage)
        XCTAssertEqual(user.custom, ["secret_note": .string("Anaking is Vader!")])
        XCTAssertEqual(user.teams?.count, 3)
    }

    func test_currentUserUpdateResponseJSON_whenMissingUser_failsSerialization() {
        let currentUserUpdateResponseJSON = XCTestCase.mockData(fromJSONFile: "UserUpdateResponse+MissingUser")
        XCTAssertThrowsError(try JSONDecoder.default.decode(
            UpdateUsersResponse.self, from: currentUserUpdateResponseJSON
        ))
    }
}
