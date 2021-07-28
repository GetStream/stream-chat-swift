//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class UserPayload_Tests: XCTestCase {
    let currentUserJSON = XCTestCase.mockData(fromFile: "CurrentUser")
    let otherUserJSON = XCTestCase.mockData(fromFile: "OtherUser")
    
    func test_currentUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload<NoExtraData>.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.name, "Broken Waterfall")
        XCTAssertEqual(
            payload.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.teams.count, 3)
    }
    
    func test_currentUserJSON_isSerialized_withCustomExtraData() throws {
        struct TestExtraData: UserExtraData {
            static var defaultValue: TestExtraData = .init(secretNote: "no secrets")
            
            let secretNote: String
            private enum CodingKeys: String, CodingKey {
                case secretNote = "secret_note"
            }
        }
        
        let payload = try JSONDecoder.default.decode(UserPayload<TestExtraData>.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.teams.count, 3)
        
        XCTAssertEqual(payload.extraData.secretNote, "Anaking is Vader!")
    }
    
    func test_otherUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload<NoExtraData>.self, from: otherUserJSON)
        XCTAssertEqual(payload.id, "bitter-cloud-0")
        XCTAssertEqual(payload.isBanned, true)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.name, "Bitter cloud")
        XCTAssertEqual(payload.createdAt, "2020-06-09T18:33:04.070518Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-09T18:33:04.075114Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-09T18:33:04.078929Z".toDate())
        XCTAssertEqual(
            payload.imageURL,
            URL(string: "https://getstream.io/random_png/?name=Bitter+cloud")!
        )
        XCTAssertEqual(payload.teams.count, 3)
        XCTAssertEqual(payload.role, .guest)
        XCTAssertEqual(payload.isOnline, true)
    }
}

class UserRequestBody_Tests: XCTestCase {
    func test_isSerialized() throws {
        let payload: UserRequestBody = .init(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: .defaultValue
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

class UserUpdateRequestBody_Tests: XCTestCase {
    func test_isSerialized() throws {
        let payload: UserUpdateRequestBody<TestExtraData> = .init(
            name: .unique,
            imageURL: .unique(),
            extraData: TestExtraData(secretNote: .unique)
        )
        
        let expected: [String: Any] = [
            "name": payload.name!,
            "image": payload.imageURL!.absoluteString,
            "secret_note": payload.extraData!.secretNote!
        ]
        
        let encodedJSON = try JSONEncoder.default.encode(payload)
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        
        AssertJSONEqual(encodedJSON, expectedJSON)
    }
}

class UserUpdateResponse_Tests: XCTestCase {
    func test_currentUserUpdateResponseJSON_isSerialized() throws {
        let currentUserUpdateResponseJSON = XCTestCase.mockData(fromFile: "UserUpdateResponse")
        let payload = try JSONDecoder.default.decode(
            UserUpdateResponse<TestExtraData>.self, from: currentUserUpdateResponseJSON
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
        XCTAssertEqual(user.extraData.secretNote, "Anaking is Vader!")
        XCTAssertEqual(user.teams.count, 3)
    }
    
    func test_currentUserUpdateResponseJSON_whenMissingUser_failsSerialization() {
        let currentUserUpdateResponseJSON = XCTestCase.mockData(fromFile: "UserUpdateResponse+MissingUser")
        XCTAssertThrowsError(try JSONDecoder.default.decode(
            UserUpdateResponse<TestExtraData>.self, from: currentUserUpdateResponseJSON
        ))
    }
}

private struct TestExtraData: UserExtraData {
    static var defaultValue: TestExtraData = .init(secretNote: nil)
    
    let secretNote: String?
    private enum CodingKeys: String, CodingKey {
        case secretNote = "secret_note"
    }
}

extension String {
    /// Converst a string to `Date`. Only for testing!
    func toDate() -> Date {
        DateFormatter.Stream.iso8601Date(from: self)!
    }
}
