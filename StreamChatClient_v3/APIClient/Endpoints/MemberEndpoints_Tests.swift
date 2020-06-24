//
// MemberEndpoints_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class MemberEndpointPayload_Tests: XCTestCase {
    let memberJSON: Data = {
        let url = Bundle(for: MemberEndpointPayload_Tests.self).url(forResource: "Member", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    func test_memberJSON_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(MemberPayload<NameAndImageExtraData>.self, from: memberJSON)
        
        XCTAssertEqual(payload.roleRawValue, "owner")
        XCTAssertEqual(payload.created, "2020-06-05T12:53:09.862721Z".toDate())
        XCTAssertEqual(payload.updated, "2020-06-05T12:53:09.862721Z".toDate())
        
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.user.isBanned, false)
        XCTAssertEqual(payload.user.unreadChannelsCount, 1)
        XCTAssertEqual(payload.user.unreadMessagesCount, 2)
        XCTAssertEqual(payload.user.created, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.lastActiveDate, "2020-06-10T13:24:00.501797Z".toDate())
        XCTAssertEqual(payload.user.updated, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.user.extraData.name, "Broken Waterfall")
        XCTAssertEqual(payload.user.extraData.imageURL,
                       URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!)
        XCTAssertEqual(payload.user.roleRawValue, "user")
        XCTAssertEqual(payload.user.isOnline, true)
    }
}
