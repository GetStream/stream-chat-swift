//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class GuestUserTokenPayload_Tests: XCTestCase {
    let guestUserDefaultExtraDataJSON = XCTestCase.mockData(fromFile: "GuestUser+DefaultExtraData")
    let guestUserNoExtraDataJSON = XCTestCase.mockData(fromFile: "GuestUser+NoExtraData")
    let guestUserCustomExtraDataJSON = XCTestCase.mockData(fromFile: "GuestUser+CustomExtraData")
    
    func test_guestUserDefaultExtraData_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(
            GuestUserTokenPayload<NameAndImageExtraData>.self,
            from: guestUserDefaultExtraDataJSON
        )
        
        XCTAssertEqual(payload.token, "123")
        XCTAssertNotNil(payload.user)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertFalse(payload.user.isBanned)
        XCTAssertEqual(payload.user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.user.extraData.name, "Broken Waterfall")
        XCTAssertEqual(
            payload.user.extraData.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.user.role, .guest)
        XCTAssertTrue(payload.user.isOnline)
    }
    
    func test_guestUserNoExtraData_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(GuestUserTokenPayload<NoExtraData>.self, from: guestUserNoExtraDataJSON)
        
        XCTAssertEqual(payload.token, "123")
        XCTAssertNotNil(payload.user)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertFalse(payload.user.isBanned)
        XCTAssertEqual(payload.user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.user.role, .guest)
        XCTAssertTrue(payload.user.isOnline)
    }
    
    func test_guestUserCustomExtraData_isSerialized() throws {
        struct TestExtraData: UserExtraData {
            static var defaultValue: TestExtraData = .init(company: "Stream")
            let company: String
        }
        
        let payload = try JSONDecoder.default.decode(GuestUserTokenPayload<TestExtraData>.self, from: guestUserCustomExtraDataJSON)
        
        XCTAssertEqual(payload.token, "123")
        XCTAssertNotNil(payload.user)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertFalse(payload.user.isBanned)
        XCTAssertEqual(payload.user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.user.extraData.company, "getstream.io")
        XCTAssertEqual(payload.user.role, .guest)
        XCTAssertTrue(payload.user.isOnline)
    }
}
