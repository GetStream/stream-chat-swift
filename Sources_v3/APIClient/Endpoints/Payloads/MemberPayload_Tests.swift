//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class MemberPayload_Tests: XCTestCase {
    let memberJSON = XCTestCase.mockData(fromFile: "Member")
    
    func test_memberJSON_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(MemberPayload<NameAndImageExtraData>.self, from: memberJSON)
        
        XCTAssertEqual(payload.role, .owner)
        XCTAssertEqual(payload.createdAt, "2020-06-05T12:53:09.862721Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-06-05T12:53:09.862721Z".toDate())
        
        XCTAssertNotNil(payload.user)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.user.isBanned, false)
        XCTAssertEqual(payload.user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.lastActiveAt, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.user.extraData.name, "Broken Waterfall")
        XCTAssertEqual(
            payload.user.extraData.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.user.role, .user)
        XCTAssertEqual(payload.user.isOnline, true)
    }
}
