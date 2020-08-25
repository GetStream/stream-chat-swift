//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class UserPayload_Tests: XCTestCase {
    let currentUserJSON = XCTestCase.mockData(fromFile: "CurrentUser")
    let otherUserJSON = XCTestCase.mockData(fromFile: "OtherUser")
    
    func test_currentUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload<NameAndImageExtraData>.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.extraData.name, "Broken Waterfall")
        XCTAssertEqual(
            payload.extraData.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.role, .user)
        XCTAssertEqual(payload.isOnline, true)
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
        
        XCTAssertEqual(payload.extraData.secretNote, "Anaking is Vader!")
    }
    
    func test_otherUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload<NameAndImageExtraData>.self, from: otherUserJSON)
        XCTAssertEqual(payload.id, "bitter-cloud-0")
        XCTAssertEqual(payload.isBanned, true)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.extraData.name, "Bitter cloud")
        XCTAssertEqual(payload.createdAt, "2020-06-09T18:33:04.070518Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-09T18:33:04.075114Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-09T18:33:04.078929Z".toDate())
        XCTAssertEqual(
            payload.extraData.imageURL,
            URL(string: "https://getstream.io/random_png/?name=Bitter+cloud")!
        )
        XCTAssertEqual(payload.role, .guest)
        XCTAssertEqual(payload.isOnline, true)
    }
    
    func test_otherUserJSON_isSerialized_withNoExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload<NoExtraData>.self, from: otherUserJSON)
        XCTAssertEqual(payload.id, "bitter-cloud-0")
        XCTAssertEqual(payload.isBanned, true)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.createdAt, "2020-06-09T18:33:04.070518Z".toDate())
        XCTAssertEqual(payload.lastActiveAt, "2020-06-09T18:33:04.075114Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-09T18:33:04.078929Z".toDate())
        XCTAssertEqual(payload.role, .guest)
        XCTAssertEqual(payload.isOnline, true)
    }
}

class UserRequestBody_Tests: XCTestCase {
    func test_isSerialized() throws {
        let payload: UserRequestBody<NameAndImageExtraData> = .init(
            id: .unique,
            extraData: .init(name: .unique, imageURL: .unique())
        )
        
        let serialized = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "id": payload.id,
            "name": payload.extraData.name!,
            "image": payload.extraData.imageURL!.absoluteString
        ]
        
        AssertJSONEqual(serialized, expected)
    }
}

extension String {
    /// Converst a string to `Date`. Only for testing!
    func toDate() -> Date {
        DateFormatter.Stream.iso8601Date(from: self)!
    }
}
