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
        let payload = try JSONDecoder.default.decode(UserPayload.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertNil(payload.deactivatedAt)
        XCTAssertEqual(payload.name, "Broken Waterfall")
        XCTAssertEqual(
            payload.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.teams.count, 3)
        XCTAssertEqual(payload.language, "pt")
    }

    func test_currentUserJSON_isSerialized_withCustomExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertNil(payload.deactivatedAt)
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.teams.count, 3)
        XCTAssertEqual(payload.language, "pt")

        XCTAssertEqual(payload.extraData, ["secret_note": .string("Anaking is Vader!")])
    }

    func test_otherUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload.self, from: otherUserJSON)
        XCTAssertEqual(payload.id, "bitter-cloud-0")
        XCTAssertEqual(payload.isBanned, true)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.name, "Bitter cloud")
        XCTAssertEqual(payload.createdAt, "2020-06-09T18:33:04.070518Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-09T18:33:04.075114Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-09T18:33:04.078929Z".toDate())
        XCTAssertNil(payload.deactivatedAt)
        XCTAssertEqual(
            payload.imageURL,
            URL(string: "https://getstream.io/random_png/?name=Bitter+cloud")!
        )
        XCTAssertEqual(payload.teams.count, 3)
        XCTAssertEqual(payload.language, "pt")
        XCTAssertEqual(payload.role, .guest)
        XCTAssertEqual(payload.isOnline, true)
    }

    func test_deactivatedUserJSON_isSerialized() throws {
        let deactivatedUserJSON = XCTestCase.mockData(fromJSONFile: "DeactivatedUser")
        let payload = try JSONDecoder.default.decode(UserPayload.self, from: deactivatedUserJSON)
        XCTAssertEqual(payload.id, "deactivated-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.name, "Deactivated Waterfall")
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.deactivatedAt, "2017-05-09T13:32:30.628Z".toDate())
        XCTAssertEqual(
            payload.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=deactivated-waterfall-5&amp;name=Deactivated+waterfall")!
        )
        XCTAssertEqual(payload.teams.count, 3)
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
    }

    func test_unread_isSerialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "Unread")
        let payload = try JSONDecoder.default.decode(CurrentUserUnreadsPayload.self, from: json)
        XCTAssertEqual(payload.totalUnreadCount, 1)
        XCTAssertEqual(payload.totalUnreadThreadsCount, 1)
        XCTAssertEqual(payload.channels[0].channelId.rawValue, "messaging:898be601-5f8b-40cc-919a-3f44e6b4fe64")
        XCTAssertEqual(payload.channels[0].unreadCount, 1)
        XCTAssertEqual(payload.channels[0].lastRead, "2024-03-11T23:00:55.941654Z".toDate())
        XCTAssertEqual(payload.channelType[0].channelType.rawValue, "messaging")
        XCTAssertEqual(payload.channelType[0].channelCount, 2)
        XCTAssertEqual(payload.channelType[0].unreadCount, 3)
        XCTAssertEqual(payload.threads[0].unreadCount, 5)
        XCTAssertEqual(payload.threads[0].lastRead, "0001-01-01T00:00:00Z".toDate())
        XCTAssertEqual(payload.threads[0].lastReadMessageId, "6e75266e-c8e9-49f9-be87-f8e745e94821")
        XCTAssertEqual(payload.threads[0].parentMessageId, "6e75266e-c8e9-49f9-be87-f8e745e94821")
    }
}

final class UserRequestBody_Tests: XCTestCase {
    func test_isSerialized() throws {
        let payload: UserRequestBody = .init(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: [:]
        )

        let serialized = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "id": payload.id,
            "name": payload.name!,
            "image": payload.imageURL!.absoluteString
        ]

        AssertJSONEqual(serialized, expected)
    }
}

final class UserUpdateRequestBody_Tests: XCTestCase {
    func test_isSerialized() throws {
        let value = String.unique

        let payload: UserUpdateRequestBody = .init(
            name: .unique,
            imageURL: .unique(),
            privacySettings: .init(
                typingIndicators: .init(enabled: true),
                readReceipts: .init(enabled: true)
            ),
            role: .admin,
            extraData: ["secret_note": .string(value)]
        )

        let expected: [String: Any] = [
            "name": payload.name!,
            "image": payload.imageURL!.absoluteString,
            "privacy_settings": [
                "typing_indicators": ["enabled": true],
                "read_receipts": ["enabled": true]
            ],
            "role": UserRole.admin.rawValue,
            "secret_note": value
        ]

        let encodedJSON = try JSONEncoder.default.encode(payload)
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])

        AssertJSONEqual(encodedJSON, expectedJSON)
    }
}

final class UserUpdateResponse_Tests: XCTestCase {
    func test_currentUserUpdateResponseJSON_isSerialized() throws {
        let currentUserUpdateResponseJSON = XCTestCase.mockData(fromJSONFile: "UserUpdateResponse")
        let payload = try JSONDecoder.default.decode(
            CurrentUserUpdateResponse.self, from: currentUserUpdateResponseJSON
        )
        let user = payload.user
        XCTAssertEqual(user.id, "luke_skywalker")
        XCTAssertEqual(user.role, .user)
        XCTAssertEqual(user.createdAt, "2020-12-07T11:36:47.059906Z".toDate())
        XCTAssertEqual(user.updatedAt, "2021-01-11T10:36:24.488391Z".toDate())
        XCTAssertEqual(user.lastActiveAt, "2021-01-08T19:16:54.380686Z".toDate())
        XCTAssertEqual(user.isBanned, false)
        XCTAssertEqual(user.isOnline, false)
        XCTAssertEqual(user.name, "Luke")
        let expectedImage = "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg"
        XCTAssertEqual(user.imageURL?.absoluteString, expectedImage)
        XCTAssertEqual(user.extraData, ["secret_note": .string("Anaking is Vader!")])
        XCTAssertEqual(user.teams.count, 3)
    }

    func test_currentUserUpdateResponseJSON_whenMissingUser_failsSerialization() {
        let currentUserUpdateResponseJSON = XCTestCase.mockData(fromJSONFile: "UserUpdateResponse+MissingUser")
        XCTAssertThrowsError(try JSONDecoder.default.decode(
            CurrentUserUpdateResponse.self, from: currentUserUpdateResponseJSON
        ))
    }
}
