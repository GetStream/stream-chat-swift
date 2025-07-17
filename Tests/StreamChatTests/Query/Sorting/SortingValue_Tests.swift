//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        ].sorted(using: sorting)

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
        ].sorted(using: sorting)

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
        ].sorted(using: sorting)

        XCTAssertEqual(result.map(\.name), ["D", "B", "E", "A", "C"])
    }
    
    // MARK: - NSSortDescriptor Comparisons
    
    func test_sortingValue_channelList_whenNonNilValues_thenEqualsToNSSortDesciptorSorting() {
        let channels = [
            makeChannel(cidIndex: 1, lastMessageAtOffset: 1, createdAtOffset: 15),
            makeChannel(cidIndex: 2, lastMessageAtOffset: 2, createdAtOffset: 14),
            makeChannel(cidIndex: 3, lastMessageAtOffset: 3, createdAtOffset: 13),
            makeChannel(cidIndex: 4, lastMessageAtOffset: 4, createdAtOffset: 12),
            makeChannel(cidIndex: 5, lastMessageAtOffset: 5, createdAtOffset: 11)
        ]
        let sortingKeys: [Sorting<ChannelListSortingKey>] = [
            Sorting(key: .lastMessageAt, isAscending: false),
            Sorting(key: .createdAt, isAscending: false)
        ]
        let runtimeSortResult = channels
            .sorted(using: sortingKeys.compactMap(\.key.sortValue))
            .map(\.cid.id)
        let nsArrayChannels = NSArray(array: channels.map { ChannelBoxed(channel: $0) })
        let sortDescriptors = sortingKeys.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        let sortDescriptorResult = (nsArrayChannels.sortedArray(using: sortDescriptors) as! [ChannelBoxed]).compactMap(\.id)
        let expectedIds = ["5", "4", "3", "2", "1"]
        XCTAssertEqual(expectedIds, sortDescriptorResult, "\(sortDescriptorResult)")
        XCTAssertEqual(expectedIds, runtimeSortResult, "\(runtimeSortResult)")
    }
    
    func test_sortingValue_channelList_whenSomeNilValues_thenEqualsToNSSortDesciptorSorting() {
        let channels = [
            makeChannel(cidIndex: 1, lastMessageAtOffset: 1, createdAtOffset: 15),
            makeChannel(cidIndex: 2, lastMessageAtOffset: nil, createdAtOffset: 14),
            makeChannel(cidIndex: 3, lastMessageAtOffset: 3, createdAtOffset: 13),
            makeChannel(cidIndex: 4, lastMessageAtOffset: nil, createdAtOffset: 12),
            makeChannel(cidIndex: 5, lastMessageAtOffset: 5, createdAtOffset: 11)
        ]
        let sortingKeys: [Sorting<ChannelListSortingKey>] = [
            Sorting(key: .lastMessageAt, isAscending: false),
            Sorting(key: .createdAt, isAscending: false)
        ]
        let sortValues = sortingKeys.compactMap(\.key.sortValue)
        XCTAssertEqual(2, sortValues.count)
        let runtimeSortResult = channels
            .sorted(using: sortValues)
            .map(\.cid.id)
        
        let nsArrayChannels = NSArray(array: channels.map { ChannelBoxed(channel: $0) })
        let sortDescriptors = sortingKeys.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        XCTAssertEqual(2, sortDescriptors.count)
        
        let sortDescriptorResult = (nsArrayChannels.sortedArray(using: sortDescriptors) as! [ChannelBoxed]).compactMap(\.id)
        let expectedIds = ["5", "3", "1", "2", "4"]
        XCTAssertEqual(expectedIds, sortDescriptorResult, "\(sortDescriptorResult)")
        XCTAssertEqual(expectedIds, runtimeSortResult, "\(runtimeSortResult)")
    }
    
    func test_sortingValue_channelList_whenSomeEqualValues_thenEqualsToNSSortDesciptorSorting() {
        let channels = [
            makeChannel(cidIndex: 1, lastMessageAtOffset: 1, createdAtOffset: 15),
            makeChannel(cidIndex: 2, lastMessageAtOffset: 3, createdAtOffset: 14),
            makeChannel(cidIndex: 3, lastMessageAtOffset: 3, createdAtOffset: 13),
            makeChannel(cidIndex: 4, lastMessageAtOffset: 3, createdAtOffset: 12),
            makeChannel(cidIndex: 5, lastMessageAtOffset: 5, createdAtOffset: 11)
        ]
        let sortingKeys: [Sorting<ChannelListSortingKey>] = [
            Sorting(key: .lastMessageAt, isAscending: false),
            Sorting(key: .createdAt, isAscending: false)
        ]
        let sortValues = sortingKeys.compactMap(\.key.sortValue)
        XCTAssertEqual(2, sortValues.count)
        let runtimeSortResult = channels
            .sorted(using: sortValues)
            .map(\.cid.id)
        
        let nsArrayChannels = NSArray(array: channels.map { ChannelBoxed(channel: $0) })
        let sortDescriptors = sortingKeys.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        XCTAssertEqual(2, sortDescriptors.count)
        
        let sortDescriptorResult = (nsArrayChannels.sortedArray(using: sortDescriptors) as! [ChannelBoxed]).compactMap(\.id)
        let expectedIds = ["5", "2", "3", "4", "1"]
        XCTAssertEqual(expectedIds, sortDescriptorResult, "\(sortDescriptorResult)")
        XCTAssertEqual(expectedIds, runtimeSortResult, "\(runtimeSortResult)")
    }
    
    func test_sortingValue_channelList_whenAllEqualValues_thenEqualsToNSSortDesciptorSortingAndInitialOrderIsKept() {
        let channels = [
            makeChannel(cidIndex: 1, lastMessageAtOffset: 1, createdAtOffset: 11),
            makeChannel(cidIndex: 2, lastMessageAtOffset: 1, createdAtOffset: 11),
            makeChannel(cidIndex: 3, lastMessageAtOffset: 1, createdAtOffset: 11),
            makeChannel(cidIndex: 4, lastMessageAtOffset: 1, createdAtOffset: 11),
            makeChannel(cidIndex: 5, lastMessageAtOffset: 1, createdAtOffset: 11)
        ]
        let sortingKeys: [Sorting<ChannelListSortingKey>] = [
            Sorting(key: .lastMessageAt, isAscending: false),
            Sorting(key: .createdAt, isAscending: false)
        ]
        let sortValues = sortingKeys.compactMap(\.key.sortValue)
        XCTAssertEqual(2, sortValues.count)
        let runtimeSortResult = channels
            .sorted(using: sortValues)
            .map(\.cid.id)
        
        let nsArrayChannels = NSArray(array: channels.map { ChannelBoxed(channel: $0) })
        let sortDescriptors = sortingKeys.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        XCTAssertEqual(2, sortDescriptors.count)
        
        let sortDescriptorResult = (nsArrayChannels.sortedArray(using: sortDescriptors) as! [ChannelBoxed]).compactMap(\.id)
        let expectedIds = ["1", "2", "3", "4", "5"]
        XCTAssertEqual(expectedIds, sortDescriptorResult, "\(sortDescriptorResult)")
        XCTAssertEqual(expectedIds, runtimeSortResult, "\(runtimeSortResult)")
    }
    
    func test_sortingValue_channelList_whenSomeEqualValuesAndDescendingAndAscending_thenEqualsToNSSortDesciptorSorting() {
        let channels = [
            makeChannel(cidIndex: 1, createdAtOffset: 1, unreadMessages: 3),
            makeChannel(cidIndex: 2, createdAtOffset: 2, unreadMessages: 0),
            makeChannel(cidIndex: 3, createdAtOffset: 3, unreadMessages: 2),
            makeChannel(cidIndex: 4, createdAtOffset: 4, unreadMessages: 0),
            makeChannel(cidIndex: 5, createdAtOffset: 5, unreadMessages: 0)
        ]
        let sortingKeys: [Sorting<ChannelListSortingKey>] = [
            Sorting(key: .unreadCount, isAscending: false),
            Sorting(key: .createdAt, isAscending: true)
        ]
        let sortValues = sortingKeys.compactMap(\.key.sortValue)
        XCTAssertEqual(2, sortValues.count)
        let runtimeSortResult = channels
            .sorted(using: sortValues)
            .map(\.cid.id)
        
        let nsArrayChannels = NSArray(array: channels.map { ChannelBoxed(channel: $0) })
        let sortDescriptors = sortingKeys.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        XCTAssertEqual(2, sortDescriptors.count)
        
        let sortDescriptorResult = (nsArrayChannels.sortedArray(using: sortDescriptors) as! [ChannelBoxed]).compactMap(\.id)
        let expectedIds = ["1", "3", "2", "4", "5"]
        XCTAssertEqual(expectedIds, sortDescriptorResult, "\(sortDescriptorResult)")
        XCTAssertEqual(expectedIds, runtimeSortResult, "\(runtimeSortResult)")
    }
    
    // MARK: -
    
    class ChannelBoxed: NSObject {
        let channel: ChatChannel
        
        init(channel: ChatChannel) {
            self.channel = channel
        }
        
        @objc var id: String? { channel.cid.id }
        @objc var lastMessageAt: NSDate? { channel.lastMessageAt as? NSDate }
        @objc var createdAt: NSDate { channel.createdAt as NSDate }
        @objc var currentUserUnreadMessagesCount: Int { channel.unreadCount.messages }
    }
    
    static let referenceDate = Date().addingTimeInterval(-3600)
    
    func makeChannel(cidIndex: Int, lastMessageAtOffset: Int? = nil, createdAtOffset: Int, unreadMessages: Int = 0) -> ChatChannel {
        ChatChannel.mock(
            cid: ChannelId(type: .messaging, id: "\(cidIndex)"),
            lastMessageAt: lastMessageAtOffset != nil ? Self.referenceDate.addingTimeInterval(TimeInterval(lastMessageAtOffset!)) : nil,
            createdAt: Self.referenceDate.addingTimeInterval(TimeInterval(createdAtOffset)),
            unreadCount: ChannelUnreadCount(messages: unreadMessages, mentions: 0)
        )
    }
}
