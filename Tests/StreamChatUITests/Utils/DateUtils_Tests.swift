//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import XCTest

class DateUtils_Tests: XCTestCase {
    func test_timeAgoNow() throws {
        XCTAssertEqual(DateUtils.timeAgo(relativeTo: Date()), "last seen just one second ago")
    }
    
    func test_timeAgoFuture() throws {
        let date = Calendar.current.date(byAdding: .second, value: 60, to: Date())!
        XCTAssertEqual(DateUtils.timeAgo(relativeTo: date), nil)
    }

    func test_timeAgo1MinuteAgo() throws {
        let date = Calendar.current.date(byAdding: .second, value: -60, to: Date())!
        XCTAssertEqual(DateUtils.timeAgo(relativeTo: date), "last seen one minute ago")
    }

    func test_timeAgo59SecondsAgo() throws {
        let date = Calendar.current.date(byAdding: .second, value: -59, to: Date())!
        XCTAssertEqual(DateUtils.timeAgo(relativeTo: date), "last seen 59 seconds ago")
    }

    func test_timeAgo42SecondsAgo() throws {
        let date = Calendar.current.date(byAdding: .second, value: -42, to: Date())!
        XCTAssertEqual(DateUtils.timeAgo(relativeTo: date), "last seen 42 seconds ago")
    }
    
    func test_timeAgo42MinutesAgo() throws {
        let date = Calendar.current.date(byAdding: .minute, value: -42, to: Date())!
        XCTAssertEqual(DateUtils.timeAgo(relativeTo: date), "last seen 42 minutes ago")
    }
    
    func test_timeAgo42DaysAgo() throws {
        let date = Calendar.current.date(byAdding: .day, value: -42, to: Date())!
        XCTAssertEqual(DateUtils.timeAgo(relativeTo: date), "last seen one month ago")
    }
    
    func test_timeAgo42WeeksAgo() throws {
        let date = Calendar.current.date(byAdding: .day, value: -42 * 7, to: Date())!
        XCTAssertEqual(DateUtils.timeAgo(relativeTo: date), "last seen 9 months ago")
    }
}
