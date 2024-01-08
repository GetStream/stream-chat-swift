//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SortingValue_Tests: XCTestCase {
    let dateNow = Date()
    let datePast = Date().addingTimeInterval(-60 * 60 * 3)
    let dateWayPast = Date().addingTimeInterval(-60 * 60 * 100)

    lazy var channel1 = ChatChannel.mockNonDMChannel(name: "A", createdAt: datePast)
    lazy var channel2 = ChatChannel.mockNonDMChannel(name: "B", createdAt: dateNow)
    lazy var channel3 = ChatChannel.mockNonDMChannel(name: "C", createdAt: dateWayPast)
    lazy var channel4 = ChatChannel.mockNonDMChannel(name: "D", createdAt: dateNow)
    lazy var channel5 = ChatChannel.mockNonDMChannel(name: "E", createdAt: datePast)

    func test_sortingValue_channelList_name() throws {
        let sorting: [SortValue<ChatChannel>] = [
            .init(keyPath: \.name, isAscending: true)
        ]

        let result = [
            channel1,
            channel2,
            channel3,
            channel4,
            channel5
        ].sort(using: sorting)

        XCTAssertEqual(result.map(\.name), ["A", "B", "C", "D", "E"])
    }

    func test_sortingValue_channelList_createdAt() throws {
        let sorting: [SortValue<ChatChannel>] = [
            .init(keyPath: \.createdAt, isAscending: false)
        ]

        let result = [
            channel1,
            channel2,
            channel3,
            channel4,
            channel5
        ].sort(using: sorting)

        XCTAssertEqual(result.map(\.name), ["B", "D", "A", "E", "C"])
    }

    func test_sortingValue_channelList_createdAtAndNameDescending() throws {
        let sorting: [SortValue<ChatChannel>] = [
            .init(keyPath: \.createdAt, isAscending: false),
            .init(keyPath: \.name, isAscending: false)
        ]

        let result = [
            channel1,
            channel2,
            channel3,
            channel4,
            channel5
        ].sort(using: sorting)

        XCTAssertEqual(result.map(\.name), ["D", "B", "E", "A", "C"])
    }
}
