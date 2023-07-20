//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelList_Sorting_Tests: XCTestCase {
    let dateNow = Date()
    let datePast = Date().addingTimeInterval(-60 * 60 * 3)
    let dateWayPast = Date().addingTimeInterval(-60 * 60 * 100)

    lazy var defaultChannels = [
        (name: "A", createdAt: datePast),
        (name: "B", createdAt: dateNow),
        (name: "C", createdAt: dateWayPast),
        (name: "D", createdAt: dateNow),
        (name: "E", createdAt: datePast)
    ]

    lazy var bulkChannels: [(name: String, createdAt: Date)] = (0...50).map { _ in
        let randomIndex = Int.random(in: 0..<defaultChannels.count)
        return defaultChannels[randomIndex]
    }

    var database: DatabaseContainer_Spy!
    var query: ChannelListQuery!
    var observer: ListDatabaseObserverWrapper<ChatChannel, ChannelDTO>!

    func test_channelsAreSortedAccordingToDefaultSorting_foreground() throws {
        try test_channelsAreSortedAccordingToDefaultSorting(isBackground: false)
    }

    func test_channelsAreSortedAccordingToDefaultSorting_background() throws {
        try test_channelsAreSortedAccordingToDefaultSorting(isBackground: true)
    }

    func test_channelsAreSortedAccordingToDefaultSorting(isBackground: Bool) throws {
        createObserver(with: [
            .init(key: .default, isAscending: false)
        ], isBackground: isBackground)

        try observer.startObserving()

        let expectation = self.expectation(description: "Observer notifies")
        observer.onDidChange = { changes in
            XCTAssertEqual(changes.count, 5)
            expectation.fulfill()
        }

        let channels = [
            (name: "A", createdAt: datePast, messageCreatedAt: Date().addingTimeInterval(-10000)),
            (name: "B", createdAt: dateNow, messageCreatedAt: Date()),
            (name: "C", createdAt: dateWayPast, messageCreatedAt: Date().addingTimeInterval(-1)),
            (name: "D", createdAt: dateNow, messageCreatedAt: Date().addingTimeInterval(-1000)),
            (name: "E", createdAt: datePast, messageCreatedAt: Date().addingTimeInterval(-60))
        ]

        try createChannels(mapping: channels)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(observer.items.count, 5)
        XCTAssertEqual(observer.items.map(\.name), ["B", "C", "E", "D", "A"])
    }

    func test_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom_foreground() throws {
        try test_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom(isBackground: false)
    }

    func test_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom_background() throws {
        try test_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom(isBackground: true)
    }

    // This test is to make sure that the default sorting mechanism using DB (vía `defaultSortingAt`) matches the same behaviour when using local custom mapping instead
    func test_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom(isBackground: Bool) throws {
        createObserver(with: [
            .init(key: .custom(keyPath: \.defaultSortingAt, key: "defaultSortingAt"), isAscending: false)
        ], isBackground: isBackground)

        try observer.startObserving()

        let expectation = self.expectation(description: "Observer notifies")
        observer.onDidChange = { changes in
            XCTAssertEqual(changes.count, 5)
            expectation.fulfill()
        }

        let channels = [
            (name: "A", createdAt: datePast, messageCreatedAt: Date().addingTimeInterval(-10000)),
            (name: "B", createdAt: dateNow, messageCreatedAt: Date()),
            (name: "C", createdAt: dateWayPast, messageCreatedAt: Date().addingTimeInterval(-1)),
            (name: "D", createdAt: dateNow, messageCreatedAt: Date().addingTimeInterval(-1000)),
            (name: "E", createdAt: datePast, messageCreatedAt: Date().addingTimeInterval(-60))
        ]

        try createChannels(mapping: channels)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(observer.items.count, 5)
        XCTAssertEqual(observer.items.map(\.name), ["B", "C", "E", "D", "A"])
    }

    func test_channelsAreSortedAccordingToCustomSorting_foreground() throws {
        try test_channelsAreSortedAccordingToCustomSorting(isBackground: false)
    }

    func test_channelsAreSortedAccordingToCustomSorting_background() throws {
        try test_channelsAreSortedAccordingToCustomSorting(isBackground: true)
    }

    func test_channelsAreSortedAccordingToCustomSorting(isBackground: Bool) throws {
        createObserver(with: [
            .init(key: .custom(keyPath: \.name, key: "name"), isAscending: false)
        ], isBackground: isBackground)
        try observer.startObserving()

        let expectation = self.expectation(description: "Observer notifies")
        observer.onDidChange = { changes in
            XCTAssertEqual(changes.count, 5)
            expectation.fulfill()
        }

        try createChannels(mapping: defaultChannels)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(observer.items.count, 5)
        XCTAssertEqual(observer.items.map(\.name), ["E", "D", "C", "B", "A"])
    }

    func test_channelsAreSortedAccordingToACombinationWithCustomSorting_foreground() throws {
        try test_channelsAreSortedAccordingToACombinationWithCustomSorting(isBackground: false)
    }

    func test_channelsAreSortedAccordingToACombinationWithCustomSorting_background() throws {
        try test_channelsAreSortedAccordingToACombinationWithCustomSorting(isBackground: true)
    }

    func test_channelsAreSortedAccordingToACombinationWithCustomSorting(isBackground: Bool) throws {
        createObserver(with: [
            .init(key: .createdAt, isAscending: false),
            .init(key: .custom(keyPath: \.name, key: "name"), isAscending: false)
        ], isBackground: isBackground)
        try observer.startObserving()

        let expectation = self.expectation(description: "Observer notifies")
        observer.onDidChange = { changes in
            XCTAssertEqual(changes.count, 5)
            expectation.fulfill()
        }

        try createChannels(mapping: defaultChannels)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(observer.items.count, 5)
        XCTAssertEqual(observer.items.map(\.name), ["D", "B", "E", "A", "C"])
    }

    func test_timeToProcessMultipleChatChannels_customSorting_foreground() throws {
        try test_timeToProcessMultipleChatChannels_customSorting(isBackground: false)
    }

    func test_timeToProcessMultipleChatChannels_customSorting_background() throws {
        try test_timeToProcessMultipleChatChannels_customSorting(isBackground: true)
    }

    func test_timeToProcessMultipleChatChannels_customSorting(isBackground: Bool) throws {
        let sorting: [Sorting<ChannelListSortingKey>] = [
            .init(key: .createdAt, isAscending: false),
            .init(key: .custom(keyPath: \.name, key: "name"), isAscending: false)
        ]

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            createObserver(with: sorting, isBackground: isBackground)
            do {
                try observer.startObserving()

                observer.onDidChange = { changes in
                    self.stopMeasuring()
                    XCTAssertEqual(changes.count, self.bulkChannels.count)
                    XCTAssertEqual(self.observer.items.count, self.bulkChannels.count)
                }

                startMeasuring()
                try createChannels(mapping: self.bulkChannels)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func test_timeToProcessMultipleChatChannels_defaultSorting_foreground() throws {
        try test_timeToProcessMultipleChatChannels_defaultSorting(isBackground: false)
    }

    func test_timeToProcessMultipleChatChannels_defaultSorting_background() throws {
        try test_timeToProcessMultipleChatChannels_defaultSorting(isBackground: true)
    }

    func test_timeToProcessMultipleChatChannels_defaultSorting(isBackground: Bool) throws {
        let sorting: [Sorting<ChannelListSortingKey>] = [
            .init(key: .default, isAscending: false)
        ]

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            createObserver(with: sorting, isBackground: isBackground)
            do {
                try observer.startObserving()

                observer.onDidChange = { changes in
                    self.stopMeasuring()
                    XCTAssertEqual(changes.count, self.bulkChannels.count)
                    XCTAssertEqual(self.observer.items.count, self.bulkChannels.count)
                }

                startMeasuring()
                try createChannels(mapping: self.bulkChannels)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers

    private func createObserver(with sorting: [Sorting<ChannelListSortingKey>], isBackground: Bool) {
        database = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
            modelName: "StreamChatModel",
            bundle: .streamChat
        )
        query = ChannelListQuery(filter: .nonEmpty, sort: sorting)

        let request = ChannelDTO.channelListFetchRequest(query: query, chatClientConfig: ChatClientConfig(apiKeyString: "1234"))

        observer = ListDatabaseObserverWrapper(
            isBackground: isBackground,
            database: database,
            fetchRequest: request,
            itemCreator: { try $0.asModel() },
            sorting: sorting.customSorting
        )

        XCTAssertEqual(observer.items.count, 0)
    }

    private func createChannels(mapping: [(name: String, createdAt: Date, messageCreatedAt: Date)]) throws {
        try database.writeSynchronously { session in
            session.saveQuery(query: self.query)
            let channels = try mapping.map {
                let (name, createdAt, messageCreatedAt) = $0
                return try session.saveChannel(
                    payload: .dummy(
                        channel: .dummy(name: name, createdAt: createdAt),
                        messages: [.dummy(createdAt: messageCreatedAt)]
                    )
                )
            }

            guard let queryDTO = session.channelListQuery(filterHash: self.query.filter.filterHash) else {
                return
            }
            for channel in channels {
                queryDTO.channels.insert(channel)
            }
        }
    }

    private func createChannels(mapping: [(name: String, createdAt: Date)]) throws {
        try createChannels(mapping: mapping.map {
            ($0, $1, $1)
        })
    }
}
