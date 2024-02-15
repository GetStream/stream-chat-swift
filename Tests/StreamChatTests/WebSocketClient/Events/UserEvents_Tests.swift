//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_userPresenceEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserPresence")
        let event = try eventDecoder.decode(from: json) as? UserPresenceChangedEvent
        XCTAssertEqual(event?.user?.id, "steep-moon-9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-16 15:44:19 +0000")
    }

    func test_watchingEvent() throws {
        var json = XCTestCase.mockData(fromJSONFile: "UserStartWatching")
        var event = try eventDecoder.decode(from: json) as? UserWatchingStartEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE").rawValue)
        XCTAssertEqual(event?.user?.id, "luke_skywalker")

        json = XCTestCase.mockData(fromJSONFile: "UserStopWatching")
        let eventStop = try eventDecoder.decode(from: json) as? UserWatchingStopEvent
        XCTAssertEqual(eventStop?.user?.id, "luke_skywalker")
        XCTAssertTrue(eventStop?.watcherCount ?? 0 > 0)
        XCTAssertEqual(eventStop?.cid, ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE").rawValue)
    }

    func test_userBannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserBanned")
        let event = try eventDecoder.decode(from: json) as? UserBannedEvent
        XCTAssertEqual(event?.user?.id, "broken-waterfall-5")
        XCTAssertEqual(event?.createdBy.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070").rawValue)
        XCTAssertEqual(event?.reason, "I don't like you 🤮")
        XCTAssertEqual(event?.shadow, true)
    }

    func test_userUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserUnbanned")
        let event = try eventDecoder.decode(from: json) as? UserUnbannedEvent
        XCTAssertEqual(event?.user?.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070").rawValue)
    }

    func test_userGloballyBannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserGloballyBanned")
        let event = try eventDecoder.decode(from: json) as? UserBannedEvent
        XCTAssertEqual(event?.user?.id, "c-3po")
        XCTAssertEqual(event?.createdAt.description, "2022-09-22 07:59:24 +0000")
    }

    func test_userGloballyUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserGloballyUnbanned")
        let event = try eventDecoder.decode(from: json) as? UserUnbannedEvent
        XCTAssertEqual(event?.user?.id, "c-3po")
        XCTAssertEqual(event?.createdAt.description, "2022-09-22 08:00:15 +0000")
    }
}
