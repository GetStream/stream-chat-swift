//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class UserEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<NoExtraData>()
    
    func test_userPresenceEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserPresence")
        let event = try eventDecoder.decode(from: json) as? UserPresenceChangedEvent<NoExtraData>
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.createdAt?.description, "2020-07-16 15:44:19 +0000")
    }
    
    func test_watchingEvent() throws {
        var json = XCTestCase.mockData(fromFile: "UserStartWatching")
        var event = try eventDecoder.decode(from: json) as? UserWatchingEvent
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertTrue(event?.isStarted ?? false)
        XCTAssertTrue(event?.watcherCount ?? 0 > 0)
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        
        json = XCTestCase.mockData(fromFile: "UserStopWatching")
        event = try eventDecoder.decode(from: json) as? UserWatchingEvent
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertFalse(event?.isStarted ?? false)
        XCTAssertTrue(event?.watcherCount ?? 0 > 0)
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
    }
    
    func test_userBannedEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserBanned")
        let event = try eventDecoder.decode(from: json) as? UserBannedEvent<NoExtraData>
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.ownerId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual(event?.reason, "I don't like you 🤮")
    }
    
    func test_userUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserUnbanned")
        let event = try eventDecoder.decode(from: json) as? UserUnbannedEvent<NoExtraData>
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
    }
}
