//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class ChannelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_channelPayload_isStoredAndLoadedFromDB() {
        let channelId: ChannelId = .unique
        
        let payload = dummyPayload(with: channelId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the fields are correct
        var loadedChannel: _ChatChannel<NoExtraData>? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        AssertAsync {
            // Channel details
            Assert.willBeEqual(channelId, loadedChannel?.cid)
            
            Assert.willBeEqual(payload.watcherCount, loadedChannel?.watcherCount)
            Assert.willBeEqual(payload.channel.name, loadedChannel?.name)
            Assert.willBeEqual(payload.channel.imageURL, loadedChannel?.imageURL)
            Assert.willBeEqual(payload.channel.memberCount, loadedChannel?.memberCount)
            Assert.willBeEqual(payload.channel.extraData, loadedChannel?.extraData)
            Assert.willBeEqual(payload.channel.typeRawValue, loadedChannel?.type.rawValue)
            Assert.willBeEqual(payload.channel.lastMessageAt, loadedChannel?.lastMessageAt)
            Assert.willBeEqual(payload.channel.createdAt, loadedChannel?.createdAt)
            Assert.willBeEqual(payload.channel.updatedAt, loadedChannel?.updatedAt)
            Assert.willBeEqual(payload.channel.deletedAt, loadedChannel?.deletedAt)
            Assert.willBeEqual(payload.channel.cooldownDuration, loadedChannel?.cooldownDuration)
            
            // Config
            Assert.willBeEqual(payload.channel.config.reactionsEnabled, loadedChannel?.config.reactionsEnabled)
            Assert.willBeEqual(payload.channel.config.typingEventsEnabled, loadedChannel?.config.typingEventsEnabled)
            Assert.willBeEqual(payload.channel.config.readEventsEnabled, loadedChannel?.config.readEventsEnabled)
            Assert.willBeEqual(payload.channel.config.connectEventsEnabled, loadedChannel?.config.connectEventsEnabled)
            Assert.willBeEqual(payload.channel.config.uploadsEnabled, loadedChannel?.config.uploadsEnabled)
            Assert.willBeEqual(payload.channel.config.repliesEnabled, loadedChannel?.config.repliesEnabled)
            Assert.willBeEqual(payload.channel.config.searchEnabled, loadedChannel?.config.searchEnabled)
            Assert.willBeEqual(payload.channel.config.mutesEnabled, loadedChannel?.config.mutesEnabled)
            Assert.willBeEqual(payload.channel.config.urlEnrichmentEnabled, loadedChannel?.config.urlEnrichmentEnabled)
            Assert.willBeEqual(payload.channel.config.messageRetention, loadedChannel?.config.messageRetention)
            Assert.willBeEqual(payload.channel.config.maxMessageLength, loadedChannel?.config.maxMessageLength)
            Assert.willBeEqual(payload.channel.config.commands, loadedChannel?.config.commands)
            Assert.willBeEqual(payload.channel.config.createdAt, loadedChannel?.config.createdAt)
            Assert.willBeEqual(payload.channel.config.updatedAt, loadedChannel?.config.updatedAt)
            
            // Creator
            Assert.willBeEqual(payload.channel.createdBy!.id, loadedChannel?.createdBy?.id)
            Assert.willBeEqual(payload.channel.createdBy!.createdAt, loadedChannel?.createdBy?.userCreatedAt)
            Assert.willBeEqual(payload.channel.createdBy!.updatedAt, loadedChannel?.createdBy?.userUpdatedAt)
            Assert.willBeEqual(payload.channel.createdBy!.lastActiveAt, loadedChannel?.createdBy?.lastActiveAt)
            Assert.willBeEqual(payload.channel.createdBy!.isOnline, loadedChannel?.createdBy?.isOnline)
            Assert.willBeEqual(payload.channel.createdBy!.isBanned, loadedChannel?.createdBy?.isBanned)
            Assert.willBeEqual(payload.channel.createdBy!.role, loadedChannel?.createdBy?.userRole)
            Assert.willBeEqual(payload.channel.createdBy!.extraData, loadedChannel?.createdBy?.extraData)
            Assert.willBeEqual(payload.channel.createdBy!.teams, loadedChannel?.createdBy?.teams)
            
            // Members
            Assert.willBeEqual(payload.members[0].role, loadedChannel?.cachedMembers.first?.memberRole)
            Assert.willBeEqual(payload.members[0].createdAt, loadedChannel?.cachedMembers.first?.memberCreatedAt)
            Assert.willBeEqual(payload.members[0].updatedAt, loadedChannel?.cachedMembers.first?.memberUpdatedAt)
            
            Assert.willBeEqual(payload.members[0].user.id, loadedChannel?.cachedMembers.first?.id)
            Assert.willBeEqual(payload.members[0].user.createdAt, loadedChannel?.cachedMembers.first?.userCreatedAt)
            Assert.willBeEqual(payload.members[0].user.updatedAt, loadedChannel?.cachedMembers.first?.userUpdatedAt)
            Assert.willBeEqual(payload.members[0].user.lastActiveAt, loadedChannel?.cachedMembers.first?.lastActiveAt)
            Assert.willBeEqual(payload.members[0].user.isOnline, loadedChannel?.cachedMembers.first?.isOnline)
            Assert.willBeEqual(payload.members[0].user.isBanned, loadedChannel?.cachedMembers.first?.isBanned)
            Assert.willBeEqual(payload.members[0].user.role, loadedChannel?.cachedMembers.first?.userRole)
            Assert.willBeEqual(payload.members[0].user.extraData, loadedChannel?.cachedMembers.first?.extraData)
            Assert.willBeEqual(payload.members[0].user.teams, loadedChannel?.cachedMembers.first?.teams)
            // Assert.willBeEqual(payload.members[0].user.isInvisible, loadedChannel?.members.first?.isInvisible)
            // Assert.willBeEqual(payload.members[0].user.devices, loadedChannel?.members.first?.devices)
            // Assert.willBeEqual(payload.members[0].user.mutedUsers, loadedChannel?.members.first?.mutedUsers)
            // Assert.willBeEqual(payload.members[0].user.unreadChannelsCount, loadedChannel?.members.first?.unreadChannelsCount)
            // Assert.willBeEqual(payload.members[0].user.unreadMessagesCount, loadedChannel?.members.first?.unreadMessagesCount)
            
            // Messages
            Assert.willBeEqual(payload.messages[0].id, loadedChannel?.latestMessages.first?.id)
            Assert.willBeEqual(payload.messages[0].type.rawValue, loadedChannel?.latestMessages.first?.type.rawValue)
            Assert.willBeEqual(payload.messages[0].text, loadedChannel?.latestMessages.first?.text)
            Assert.willBeEqual(payload.messages[0].updatedAt, loadedChannel?.latestMessages.first?.updatedAt)
            Assert.willBeEqual(payload.messages[0].createdAt, loadedChannel?.latestMessages.first?.createdAt)
            Assert.willBeEqual(payload.messages[0].deletedAt, loadedChannel?.latestMessages.first?.deletedAt)
            Assert.willBeEqual(payload.messages[0].args, loadedChannel?.latestMessages.first?.arguments)
            Assert.willBeEqual(payload.messages[0].command, loadedChannel?.latestMessages.first?.command)
            Assert.willBeEqual(payload.messages[0].extraData, loadedChannel?.latestMessages.first?.extraData)
            Assert.willBeEqual(payload.messages[0].isSilent, loadedChannel?.latestMessages.first?.isSilent)
            Assert.willBeEqual(payload.messages[0].mentionedUsers.count, loadedChannel?.latestMessages.first?.mentionedUsers.count)
            Assert.willBeEqual(payload.messages[0].parentId, loadedChannel?.latestMessages.first?.parentMessageId)
            Assert.willBeEqual(payload.messages[0].reactionScores, loadedChannel?.latestMessages.first?.reactionScores)
            Assert.willBeEqual(payload.messages[0].replyCount, loadedChannel?.latestMessages.first?.replyCount)
            
            // Message user
            Assert.willBeEqual(payload.messages[0].user.id, loadedChannel?.latestMessages.first?.author.id)
            Assert.willBeEqual(payload.messages[0].user.createdAt, loadedChannel?.latestMessages.first?.author.userCreatedAt)
            Assert.willBeEqual(payload.messages[0].user.updatedAt, loadedChannel?.latestMessages.first?.author.userUpdatedAt)
            Assert.willBeEqual(payload.messages[0].user.lastActiveAt, loadedChannel?.latestMessages.first?.author.lastActiveAt)
            Assert.willBeEqual(payload.messages[0].user.isOnline, loadedChannel?.latestMessages.first?.author.isOnline)
            Assert.willBeEqual(payload.messages[0].user.isBanned, loadedChannel?.latestMessages.first?.author.isBanned)
            Assert.willBeEqual(payload.messages[0].user.role, loadedChannel?.latestMessages.first?.author.userRole)
            Assert.willBeEqual(payload.messages[0].user.extraData, loadedChannel?.latestMessages.first?.author.extraData)
            Assert.willBeEqual(payload.messages[0].user.teams, loadedChannel?.latestMessages.first?.author.teams)
            
            // Read
            Assert.willBeEqual(payload.channelReads[0].lastReadAt, loadedChannel?.reads.first?.lastReadAt)
            Assert.willBeEqual(payload.channelReads[0].unreadMessagesCount, loadedChannel?.reads.first?.unreadMessagesCount)
            Assert.willBeEqual(payload.channelReads[0].user.id, loadedChannel?.reads.first?.user.id)
        }
    }
    
    func test_DTO_updateFromSamePayload_doNotProduceChanges() throws {
        // Arrange: Store random channel payload to db
        let channelId: ChannelId = .unique
        let payload = ChannelDetailPayload.dummy(cid: channelId)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload, query: nil)
        }

        // Act: Save payload again
        let channel = try database.viewContext.saveChannel(payload: payload, query: nil)

        // Assert: DTO should not contain any changes
        XCTAssertFalse(channel.hasPersistentChangedValues)
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let channelId: ChannelId = .unique
        
        let payload = dummyPayloadWithNoExtraData(with: channelId)
        
        // Save the payload to the db
        try database.writeSynchronously { session in
            let channelDTO = try session.saveChannel(payload: payload)
            // Make the extra data JSON invalid
            channelDTO.extraData = #"{"invalid": json}"# .data(using: .utf8)!
        }
        
        // Load the channel from the db and check the fields are correct
        let loadedChannel: ChatChannel? = database.viewContext.channel(cid: channelId)?.asModel()
        
        XCTAssertEqual(loadedChannel?.extraData, .defaultValue)
    }
    
    func test_channelWithChannelListQuery_isSavedAndLoaded() {
        let query = ChannelListQuery(
            filter: .and([.less(.createdAt, than: .unique), .exists(.deletedAt, exists: false)])
        )
        
        // Create two channels
        let channel1Id: ChannelId = .unique
        let payload1 = dummyPayload(with: channel1Id)
        
        let channel2Id: ChannelId = .unique
        let payload2 = dummyPayload(with: channel2Id)
        
        // Save the channels to DB, but only channel 1 is associated with the query
        try! database.writeSynchronously { session in
            try session.saveChannel(payload: payload1, query: query)
            try session.saveChannel(payload: payload2)
        }
        
        let fetchRequest = ChannelDTO.channelListFetchRequest(query: query)
        var loadedChannels: [ChannelDTO] {
            try! database.viewContext.fetch(fetchRequest)
        }
        
        XCTAssertEqual(loadedChannels.count, 1)
        XCTAssertEqual(loadedChannels.first?.cid, channel1Id.rawValue)
    }
    
    func test_channelListQuery_withSorting() {
        // Create two channels queries with different sortings.
        let filter: Filter<ChannelListFilterScope> = .in(.members, values: [.unique])
        let queryWithDefaultSorting = _ChannelListQuery(filter: filter)
        let queryWithUpdatedAtSorting = _ChannelListQuery(filter: filter, sort: [.init(key: .updatedAt, isAscending: false)])

        // Create dummy channels payloads with ids: a, b, c, d.
        let payload1 = dummyPayload(with: try! .init(cid: "a:a"))
        let payload2 = dummyPayload(with: try! .init(cid: "a:b"))
        let payload3 = dummyPayload(with: try! .init(cid: "a:c"))
        let payload4 = dummyPayload(with: try! .init(cid: "a:d"))

        // Get `lastMessageDate` and `created` dates from generated dummy channels and sort the for the default sorting.
        let createdAndLastMessageDates = [payload1, payload2, payload3, payload4]
            .map { $0.channel.lastMessageAt ?? $0.channel.createdAt }
            .sorted(by: { $0 > $1 })
        
        // Get `updatedAt` dates from generated dummy channels and sort the for the updatedAt sorting.
        let updatedAtDates = [payload1, payload2, payload3, payload4]
            .map(\.channel.updatedAt)
            .sorted(by: { $0 > $1 })

        // Save the channels to DB. It doesn't matter which query we use because the filter for both of them is the same.
        try! database.writeSynchronously { session in
            try session.saveChannel(payload: payload1, query: queryWithDefaultSorting)
            try session.saveChannel(payload: payload2, query: queryWithDefaultSorting)
            try session.saveChannel(payload: payload3, query: queryWithDefaultSorting)
            try session.saveChannel(payload: payload4, query: queryWithDefaultSorting)
        }

        // A fetch request with a default sorting.
        let fetchRequestWithDefaultSorting = ChannelDTO.channelListFetchRequest(query: queryWithDefaultSorting)
        // A fetch request with a sorting by `updatedAt`.
        let fetchRequestWithUpdatedAtSorting = ChannelDTO.channelListFetchRequest(query: queryWithUpdatedAtSorting)

        var channelsWithDefaultSorting: [ChannelDTO] { try! database.viewContext.fetch(fetchRequestWithDefaultSorting) }
        var channelsWithUpdatedAtSorting: [ChannelDTO] { try! database.viewContext.fetch(fetchRequestWithUpdatedAtSorting) }

        // Check the default sorting.
        XCTAssertEqual(channelsWithDefaultSorting.count, 4)
        XCTAssertEqual(channelsWithDefaultSorting.map { $0.lastMessageAt ?? $0.createdAt }, createdAndLastMessageDates)

        // Check the sorting by `updatedAt`.
        XCTAssertEqual(channelsWithUpdatedAtSorting.count, 4)
        XCTAssertEqual(channelsWithUpdatedAtSorting.map(\.updatedAt), updatedAtDates)
    }

    /// `ChannelListSortingKey` test for sort descriptor and encoded value.
    func test_channelListSortingKey() {
        let encoder = JSONEncoder.stream

        var channelListSortingKey = ChannelListSortingKey.default
        XCTAssertEqual(encoder.encodedString(channelListSortingKey), "updated_at")
        XCTAssertEqual(
            channelListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "defaultSortingAt", ascending: true)
        )
        XCTAssertEqual(
            channelListSortingKey.sortDescriptor(isAscending: false),
            NSSortDescriptor(key: "defaultSortingAt", ascending: false)
        )
        XCTAssertEqual(
            ChannelListSortingKey.defaultSortDescriptor,
            NSSortDescriptor(key: "defaultSortingAt", ascending: false)
        )

        channelListSortingKey = .createdAt
        XCTAssertEqual(encoder.encodedString(channelListSortingKey), "created_at")
        XCTAssertEqual(
            channelListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        )

        channelListSortingKey = .memberCount
        XCTAssertEqual(encoder.encodedString(channelListSortingKey), "member_count")
        XCTAssertEqual(
            channelListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "memberCount", ascending: true)
        )

        channelListSortingKey = .lastMessageAt
        XCTAssertEqual(encoder.encodedString(channelListSortingKey), "last_message_at")
        XCTAssertEqual(
            channelListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "lastMessageAt", ascending: true)
        )
    }
    
    func test_channelUnreadCount_calculatedCorrectly() {
        // Create and save a current user, to be used for channel unread calculations
        try! database.createCurrentUser(id: "dummyCurrentUser")
        
        let channelId: ChannelId = .unique
        
        let payload = dummyPayload(with: channelId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the if fields are correct
        var loadedChannel: _ChatChannel<NoExtraData>? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.unreadCount.messages, self.dummyChannelRead.unreadMessagesCount)
            Assert.willBeEqual(loadedChannel?.unreadCount.mentionedMessages, 1)
        }
    }
    
    func test_typingMembers_areCleared_onResetEphemeralValues() throws {
        let cid: ChannelId = .unique
        let memberId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        // Create member in the database
        try database.createMember(userId: memberId, cid: cid)
        // Set created member as a typing member
        try database.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: cid))
            let member = try XCTUnwrap(session.member(userId: memberId, cid: cid))
            channel.currentlyTypingMembers.insert(member)
        }
        
        // Load the channel
        var channel: ChatChannel {
            database.viewContext.channel(cid: cid)!.asModel()
        }
        
        // Assert channel's currentlyTypingMembers are not empty
        XCTAssertFalse(channel.currentlyTypingMembers.isEmpty)
        
        // Simulate `resetEphemeralValues`
        database.resetEphemeralValues()
        
        // Assert channel's currentlyTypingMembers are cleared
        AssertAsync.willBeTrue(channel.currentlyTypingMembers.isEmpty)
    }
}

extension XCTestCase {
    // MARK: - Dummy data with extra data
    
    var dummyCurrentUser: CurrentUserPayload<NoExtraData> {
        CurrentUserPayload(
            id: "dummyCurrentUser",
            name: .unique,
            imageURL: nil,
            role: .user,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: false,
            isBanned: false,
            extraData: .defaultValue
        )
    }
    
    var dummyUser: UserPayload<NoExtraData> {
        dummyUser(id: .unique)
    }
    
    func dummyUser(id: String) -> UserPayload<NoExtraData> {
        UserPayload(
            id: id,
            name: .unique,
            imageURL: .unique(),
            role: .user,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: .defaultValue
        )
    }
    
    var dummyMessage: MessagePayload<NoExtraData> {
        MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            createdAt: Date(timeIntervalSince1970: 2), // See dummyChannelRead.lastReadAt below for reason
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 0,
            extraData: .defaultValue,
            reactionScores: ["like": 1],
            isSilent: false,
            attachments: []
        )
    }
    
    var dummyChannelRead: ChannelReadPayload<NoExtraData> {
        ChannelReadPayload(user: dummyCurrentUser, lastReadAt: Date(timeIntervalSince1970: 1), unreadMessagesCount: 10)
    }
    
    func dummyPayload(with channelId: ChannelId, numberOfMessages: Int = 1) -> ChannelPayload<NoExtraData> {
        let member: MemberPayload<NoExtraData> =
            .init(
                user: .init(
                    id: .unique,
                    name: .unique,
                    imageURL: nil,
                    role: .admin,
                    createdAt: .unique,
                    updatedAt: .unique,
                    lastActiveAt: .unique,
                    isOnline: true,
                    isInvisible: true,
                    isBanned: true,
                    teams: [],
                    extraData: .defaultValue
                ),
                role: .moderator,
                createdAt: .unique,
                updatedAt: .unique
            )
        
        let channelCreatedDate = Date.unique
        let lastMessageAt: Date? = Bool.random() ? channelCreatedDate.addingTimeInterval(.random(in: 100_000...900_000)) : nil

        var messages: [MessagePayload<NoExtraData>] = []
        for _ in 0..<numberOfMessages {
            messages += [dummyMessage]
        }

        let payload: ChannelPayload<NoExtraData> =
            .init(
                channel: .init(
                    cid: channelId,
                    name: .unique,
                    imageURL: .unique(),
                    extraData: .defaultValue,
                    typeRawValue: channelId.type.rawValue,
                    lastMessageAt: lastMessageAt,
                    createdAt: channelCreatedDate,
                    deletedAt: nil,
                    updatedAt: .unique,
                    createdBy: dummyUser,
                    config: .init(
                        reactionsEnabled: true,
                        typingEventsEnabled: true,
                        readEventsEnabled: true,
                        connectEventsEnabled: true,
                        uploadsEnabled: true,
                        repliesEnabled: true,
                        searchEnabled: true,
                        mutesEnabled: true,
                        urlEnrichmentEnabled: true,
                        messageRetention: "1000",
                        maxMessageLength: 100,
                        commands: [
                            .init(
                                name: "test",
                                description: "test commant",
                                set: "test",
                                args: "test"
                            )
                        ],
                        createdAt: .unique,
                        updatedAt: .unique
                    ),
                    isFrozen: true,
                    memberCount: 100,
                    team: "",
                    members: [member],
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: 10,
                members: [member],
                messages: messages,
                channelReads: [dummyChannelRead]
            )
        
        return payload
    }
    
    // MARK: - Dummy data with no extra data
    
    enum NoExtraDataTypes: ExtraDataTypes {
        typealias Channel = NoExtraData
        typealias Message = NoExtraData
        typealias User = NoExtraData
        typealias Attachment = NoExtraData
    }
    
    var dummyMessageWithNoExtraData: MessagePayload<NoExtraDataTypes> {
        MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            createdAt: .unique,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            mentionedUsers: [],
            replyCount: 0,
            extraData: NoExtraData(),
            reactionScores: [:],
            isSilent: false,
            attachments: []
        )
    }
    
    var dummyChannelReadWithNoExtraData: ChannelReadPayload<NoExtraDataTypes> {
        ChannelReadPayload(user: dummyUser, lastReadAt: .unique, unreadMessagesCount: .random(in: 0...10))
    }
    
    func dummyPayloadWithNoExtraData(with channelId: ChannelId) -> ChannelPayload<NoExtraDataTypes> {
        let member: MemberPayload<NoExtraData> =
            .init(
                user: .init(
                    id: .unique,
                    name: .unique,
                    imageURL: nil,
                    role: .admin,
                    createdAt: .unique,
                    updatedAt: .unique,
                    lastActiveAt: .unique,
                    isOnline: true,
                    isInvisible: true,
                    isBanned: true,
                    teams: [],
                    extraData: .init()
                ),
                role: .member,
                createdAt: .unique,
                updatedAt: .unique
            )
        
        let payload: ChannelPayload<NoExtraDataTypes> =
            .init(
                channel: .init(
                    cid: channelId,
                    name: .unique,
                    imageURL: .unique(),
                    extraData: .init(),
                    typeRawValue: channelId.type.rawValue,
                    lastMessageAt: .unique,
                    createdAt: .unique,
                    deletedAt: .unique,
                    updatedAt: .unique,
                    createdBy: dummyUser,
                    config: .init(
                        reactionsEnabled: true,
                        typingEventsEnabled: true,
                        readEventsEnabled: true,
                        connectEventsEnabled: true,
                        uploadsEnabled: true,
                        repliesEnabled: true,
                        searchEnabled: true,
                        mutesEnabled: true,
                        urlEnrichmentEnabled: true,
                        messageRetention: "1000",
                        maxMessageLength: 100,
                        commands: [
                            .init(
                                name: "test",
                                description: "test commant",
                                set: "test",
                                args: "test"
                            )
                        ],
                        createdAt: .unique,
                        updatedAt: .unique
                    ),
                    isFrozen: true,
                    memberCount: 100,
                    team: "",
                    members: nil,
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: 10,
                members: [member],
                messages: [dummyMessageWithNoExtraData],
                channelReads: [dummyChannelReadWithNoExtraData]
            )
        
        return payload
    }
}
