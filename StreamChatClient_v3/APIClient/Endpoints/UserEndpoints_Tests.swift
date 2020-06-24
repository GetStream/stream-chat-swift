//
// UserEndpoints_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class UserEndpointPayload_Tests: XCTestCase {
    let currentUserJSON: Data = {
        let url = Bundle(for: UserEndpointPayload_Tests.self).url(forResource: "CurrentUser", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    let otherUserJSON: Data = {
        let url = Bundle(for: UserEndpointPayload_Tests.self).url(forResource: "OtherUser", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    func test_currentUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload<NameAndImageExtraData>.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.unreadChannelsCount, 1)
        XCTAssertEqual(payload.unreadMessagesCount, 2)
        XCTAssertEqual(payload.created, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveDate, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updated, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.extraData.name, "Broken Waterfall")
        XCTAssertEqual(payload.extraData.imageURL,
                       URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!)
        XCTAssertEqual(payload.roleRawValue, "user")
        XCTAssertEqual(payload.isOnline, true)
    }
    
    func test_currentUserJSON_isSerialized_withCustomExtraData() throws {
        struct TestExtraData: UserExtraData {
            let secretNote: String
            private enum CodingKeys: String, CodingKey {
                case secretNote = "secret_note"
            }
        }
        
        let payload = try JSONDecoder.default.decode(UserPayload<TestExtraData>.self, from: currentUserJSON)
        XCTAssertEqual(payload.id, "broken-waterfall-5")
        XCTAssertEqual(payload.isBanned, false)
        XCTAssertEqual(payload.unreadChannelsCount, 1)
        XCTAssertEqual(payload.unreadMessagesCount, 2)
        XCTAssertEqual(payload.created, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.lastActiveDate, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.updated, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.roleRawValue, "user")
        XCTAssertEqual(payload.isOnline, true)
        
        XCTAssertEqual(payload.extraData.secretNote, "Anaking is Vader!")
    }
    
    func test_otherUserJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload<NameAndImageExtraData>.self, from: otherUserJSON)
        XCTAssertEqual(payload.id, "bitter-cloud-0")
        XCTAssertEqual(payload.isBanned, true)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.extraData.name, "Bitter cloud")
        XCTAssertEqual(payload.created, "2020-06-09T18:33:04.070518Z".toDate())
        XCTAssertEqual(payload.lastActiveDate, "2020-06-09T18:33:04.075114Z".toDate())
        XCTAssertEqual(payload.updated, "2020-06-09T18:33:04.078929Z".toDate())
        XCTAssertEqual(payload.extraData.imageURL,
                       URL(string: "https://getstream.io/random_png/?name=Bitter+cloud")!)
        XCTAssertEqual(payload.roleRawValue, "guest")
        XCTAssertEqual(payload.isOnline, true)
    }
    
    func test_otherUserJSON_isSerialized_withNoExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserPayload<NoExtraData>.self, from: otherUserJSON)
        XCTAssertEqual(payload.id, "bitter-cloud-0")
        XCTAssertEqual(payload.isBanned, true)
        XCTAssertEqual(payload.isOnline, true)
        XCTAssertEqual(payload.created, "2020-06-09T18:33:04.070518Z".toDate())
        XCTAssertEqual(payload.lastActiveDate, "2020-06-09T18:33:04.075114Z".toDate())
        XCTAssertEqual(payload.updated, "2020-06-09T18:33:04.078929Z".toDate())
        XCTAssertEqual(payload.roleRawValue, "guest")
        XCTAssertEqual(payload.isOnline, true)
    }
}

extension String {
    /// Converst a string to `Date`. Only for testing!
    func toDate() -> Date {
        DateFormatter.Stream.iso8601Date(from: self)!
    }
}
