//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ListDatabaseObserver_Sorting_Tests: XCTestCase {
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

    private static var originalIsBackgroundMappingEnabled = StreamRuntimeCheck._isBackgroundMappingEnabled

    override class func setUp() {
        super.setUp()
        originalIsBackgroundMappingEnabled = StreamRuntimeCheck._isBackgroundMappingEnabled
    }

    override class func tearDown() {
        super.tearDown()
        StreamRuntimeCheck._isBackgroundMappingEnabled = originalIsBackgroundMappingEnabled
    }

    override func tearDown() {
        super.tearDown()
        database = nil
        query = nil
        observer = nil
    }

    func test_channelsAreSortedAccordingToDefaultSorting_foreground() throws {
        try assert_channelsAreSortedAccordingToDefaultSorting(isBackground: false)
    }

    func test_channelsAreSortedAccordingToDefaultSorting_background() throws {
        try assert_channelsAreSortedAccordingToDefaultSorting(isBackground: true)
    }

    func assert_channelsAreSortedAccordingToDefaultSorting(isBackground: Bool) throws {
        createObserver(with: [
            .init(key: .default, isAscending: false)
        ], isBackground: isBackground)

        try startObservingAndWaitForInitialUpdate()

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
        try assert_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom(isBackground: false)
    }

    func test_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom_background() throws {
        try assert_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom(isBackground: true)
    }

    // This test is to make sure that the default sorting mechanism using DB (vía `defaultSortingAt`) matches the same behaviour when using local custom mapping instead
    func assert_channelsAreSortedAccordingToDefaultSorting_forcingItViaCustom(isBackground: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        createObserver(with: [
            .init(key: .custom(keyPath: \.defaultSortingAt, key: "defaultSortingAt"), isAscending: false)
        ], isBackground: isBackground)

        try startObservingAndWaitForInitialUpdate()

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

    func test_channelsAreSortedAccordingToRuntimeSorting_foreground() throws {
        try assert_channelsAreSortedAccordingToRuntimeSorting(isBackground: false)
    }

    func test_channelsAreSortedAccordingToRuntimeSorting_background() throws {
        try assert_channelsAreSortedAccordingToRuntimeSorting(isBackground: true)
    }

    func assert_channelsAreSortedAccordingToRuntimeSorting(isBackground: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        createObserver(with: [
            .init(key: .custom(keyPath: \.name, key: "name"), isAscending: false)
        ], isBackground: isBackground)
        try startObservingAndWaitForInitialUpdate()

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

    func test_channelsAreSortedAccordingToBoolSorting_foreground() throws {
        try assert_channelsAreSortedAccordingToBoolSorting(isBackground: false)
    }

    func test_channelsAreSortedAccordingToBoolSorting_background() throws {
        try assert_channelsAreSortedAccordingToBoolSorting(isBackground: true)
    }

    func assert_channelsAreSortedAccordingToBoolSorting(isBackground: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        createObserver(with: [
            .init(key: .custom(keyPath: \.isPinned, key: "is_pinned"), isAscending: true),
            .init(key: .custom(keyPath: \.name, key: "name"), isAscending: true)
        ], isBackground: isBackground)
        try startObservingAndWaitForInitialUpdate()

        let expectation = self.expectation(description: "Observer notifies")
        expectation.expectedFulfillmentCount = 2
        observer.onDidChange = { _ in
            expectation.fulfill()
        }

        let cids = try createChannels(mapping: defaultChannels)
        let extra: [String: RawJSON] = ["is_pinned": .bool(true)]
        let extraData = try JSONEncoder.default.encode(extra)
        let namesToUpdate = ["B", "E"]
        try database.writeSynchronously { session in
            cids.forEach {
                guard let channelDTO = session.channel(cid: $0) else {
                    XCTFail()
                    return
                }
                guard let name = channelDTO.name, namesToUpdate.contains(name) else { return }
                channelDTO.extraData = extraData
            }
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(observer.items.count, 5)
        XCTAssertEqual(observer.items.map(\.name), ["B", "E", "A", "C", "D"])
    }

    func test_channelsAreSortedAccordingToACombinationWithRuntimeSorting_foreground() throws {
        try assert_channelsAreSortedAccordingToACombinationWithRuntimeSorting(isBackground: false)
    }

    func test_channelsAreSortedAccordingToACombinationWithRuntimeSorting_background() throws {
        try assert_channelsAreSortedAccordingToACombinationWithRuntimeSorting(isBackground: true)
    }

    func assert_channelsAreSortedAccordingToACombinationWithRuntimeSorting(isBackground: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        createObserver(with: [
            .init(key: .createdAt, isAscending: false),
            .init(key: .custom(keyPath: \.name, key: "name"), isAscending: false)
        ], isBackground: isBackground)
        try startObservingAndWaitForInitialUpdate()

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

    func test_timeToProcessMultipleChatChannels_runtimeSorting_foreground() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            do {
                try assert_timeToProcessMultipleChatChannels_runtimeSorting(isBackground: false)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func test_timeToProcessMultipleChatChannels_runtimeSorting_background() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            do {
                try assert_timeToProcessMultipleChatChannels_runtimeSorting(isBackground: true)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func assert_timeToProcessMultipleChatChannels_runtimeSorting(isBackground: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        let expectation = self.expectation(description: "observer is notified")

        let sorting: [Sorting<ChannelListSortingKey>] = [
            .init(key: .createdAt, isAscending: false),
            .init(key: .custom(keyPath: \.name, key: "name"), isAscending: false)
        ]

        createObserver(with: sorting, isBackground: isBackground)
        try startObservingAndWaitForInitialUpdate()

        observer.onDidChange = { changes in
            expectation.fulfill()
            XCTAssertEqual(changes.count, self.bulkChannels.count)
            XCTAssertEqual(self.observer.items.count, self.bulkChannels.count)
        }

        startMeasuring()
        try createChannels(mapping: bulkChannels)

        waitForExpectations(timeout: defaultTimeout)
        stopMeasuring()
    }

    func test_timeToProcessMultipleChatChannels_defaultSorting_foreground() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            do {
                try assert_timeToProcessMultipleChatChannels_defaultSorting(isBackground: false)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func test_timeToProcessMultipleChatChannels_defaultSorting_background() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            do {
                try assert_timeToProcessMultipleChatChannels_defaultSorting(isBackground: true)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func assert_timeToProcessMultipleChatChannels_defaultSorting(isBackground: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        let expectation = self.expectation(description: "observer is notified")

        let sorting: [Sorting<ChannelListSortingKey>] = [
            .init(key: .default, isAscending: false)
        ]

        createObserver(with: sorting, isBackground: isBackground)
        try startObservingAndWaitForInitialUpdate()

        observer.onDidChange = { changes in
            expectation.fulfill()
            XCTAssertEqual(changes.count, self.bulkChannels.count)
            XCTAssertEqual(self.observer.items.count, self.bulkChannels.count)
        }

        startMeasuring()
        try createChannels(mapping: bulkChannels)

        waitForExpectations(timeout: defaultTimeout)
        stopMeasuring()
    }

    // MARK: - Helpers

    private func createObserver(with sorting: [Sorting<ChannelListSortingKey>], isBackground: Bool) {
        StreamRuntimeCheck._isBackgroundMappingEnabled = isBackground
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
            sorting: sorting.runtimeSorting
        )

        XCTAssertEqual(observer.items.count, 0)
    }

    @discardableResult
    private func createChannels(mapping: [(name: String, createdAt: Date, messageCreatedAt: Date)]) throws -> [ChannelId] {
        var cids: [ChannelId] = []
        try database.writeSynchronously { session in
            session.saveQuery(query: self.query)
            let channels = try mapping.map { (name, createdAt, messageCreatedAt) -> ChannelDTO in
                try session.saveChannel(
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
            cids = channels.compactMap { try? ChannelId(cid: $0.cid) }
        }
        return cids
    }

    @discardableResult
    private func createChannels(mapping: [(name: String, createdAt: Date)]) throws -> [ChannelId] {
        try createChannels(mapping: mapping.map {
            ($0, $1, $1)
        })
    }

    private func startObservingAndWaitForInitialUpdate(file: StaticString = #file, line: UInt = #line) throws {
        try observer.startObservingAndWaitForInitialUpdate(on: self, file: file, line: line)
    }
}

private extension ChatChannel {
    var isPinned: Bool {
        extraData["is_pinned"]?.boolValue ?? false
    }
}
