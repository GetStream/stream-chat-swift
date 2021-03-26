//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class ChannelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!

    // The channel payloads are created with this date, so it is easier to create messages above or below this date
    // which is useful for tests related with the createdAt date of the messages.
    static let channelCreatedDate = Date.unique
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }
    
    func test_channelPayload_isStoredAndLoadedFromDB() throws {
        let channelId: ChannelId = .unique
        
        let payload = dummyPayload(with: channelId, pinnedMessages: [dummyPinnedMessage])
        
        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the fields are correct
        let loadedChannel: ChatChannel = try XCTUnwrap(
            database.viewContext.channel(cid: channelId)?.asModel()
        )
        
        AssertAsync {
            // Channel details
            Assert.willBeEqual(channelId, loadedChannel.cid)
            
            Assert.willBeEqual(payload.watcherCount, loadedChannel.watcherCount)
            Assert.willBeEqual(Set(payload.watchers?.map(\.id) ?? []), Set(loadedChannel.lastActiveWatchers.map(\.id)))
            Assert.willBeEqual(payload.channel.name, loadedChannel.name)
            Assert.willBeEqual(payload.channel.imageURL, loadedChannel.imageURL)
            Assert.willBeEqual(payload.channel.memberCount, loadedChannel.memberCount)
            Assert.willBeEqual(payload.channel.extraData, loadedChannel.extraData)
            Assert.willBeEqual(payload.channel.typeRawValue, loadedChannel.type.rawValue)
            Assert.willBeEqual(payload.channel.lastMessageAt, loadedChannel.lastMessageAt)
            Assert.willBeEqual(payload.channel.createdAt, loadedChannel.createdAt)
            Assert.willBeEqual(payload.channel.updatedAt, loadedChannel.updatedAt)
            Assert.willBeEqual(payload.channel.deletedAt, loadedChannel.deletedAt)
            Assert.willBeEqual(payload.channel.cooldownDuration, loadedChannel.cooldownDuration)
            Assert.willBeEqual(payload.channel.team!, loadedChannel.team)
            
            // Config
            Assert.willBeEqual(payload.channel.config.reactionsEnabled, loadedChannel.config.reactionsEnabled)
            Assert.willBeEqual(payload.channel.config.typingEventsEnabled, loadedChannel.config.typingEventsEnabled)
            Assert.willBeEqual(payload.channel.config.readEventsEnabled, loadedChannel.config.readEventsEnabled)
            Assert.willBeEqual(payload.channel.config.connectEventsEnabled, loadedChannel.config.connectEventsEnabled)
            Assert.willBeEqual(payload.channel.config.uploadsEnabled, loadedChannel.config.uploadsEnabled)
            Assert.willBeEqual(payload.channel.config.repliesEnabled, loadedChannel.config.repliesEnabled)
            Assert.willBeEqual(payload.channel.config.searchEnabled, loadedChannel.config.searchEnabled)
            Assert.willBeEqual(payload.channel.config.mutesEnabled, loadedChannel.config.mutesEnabled)
            Assert.willBeEqual(payload.channel.config.urlEnrichmentEnabled, loadedChannel.config.urlEnrichmentEnabled)
            Assert.willBeEqual(payload.channel.config.messageRetention, loadedChannel.config.messageRetention)
            Assert.willBeEqual(payload.channel.config.maxMessageLength, loadedChannel.config.maxMessageLength)
            Assert.willBeEqual(payload.channel.config.commands, loadedChannel.config.commands)
            Assert.willBeEqual(payload.channel.config.createdAt, loadedChannel.config.createdAt)
            Assert.willBeEqual(payload.channel.config.updatedAt, loadedChannel.config.updatedAt)
            
            // Creator
            Assert.willBeEqual(payload.channel.createdBy!.id, loadedChannel.createdBy?.id)
            Assert.willBeEqual(payload.channel.createdBy!.createdAt, loadedChannel.createdBy?.userCreatedAt)
            Assert.willBeEqual(payload.channel.createdBy!.updatedAt, loadedChannel.createdBy?.userUpdatedAt)
            Assert.willBeEqual(payload.channel.createdBy!.lastActiveAt, loadedChannel.createdBy?.lastActiveAt)
            Assert.willBeEqual(payload.channel.createdBy!.isOnline, loadedChannel.createdBy?.isOnline)
            Assert.willBeEqual(payload.channel.createdBy!.isBanned, loadedChannel.createdBy?.isBanned)
            Assert.willBeEqual(payload.channel.createdBy!.role, loadedChannel.createdBy?.userRole)
            Assert.willBeEqual(payload.channel.createdBy!.extraData, loadedChannel.createdBy?.extraData)
            
            // Members
            Assert.willBeEqual(payload.members[0].role, loadedChannel.lastActiveMembers.first?.memberRole)
            Assert.willBeEqual(payload.members[0].createdAt, loadedChannel.lastActiveMembers.first?.memberCreatedAt)
            Assert.willBeEqual(payload.members[0].updatedAt, loadedChannel.lastActiveMembers.first?.memberUpdatedAt)
            
            Assert.willBeEqual(payload.members[0].user.id, loadedChannel.lastActiveMembers.first?.id)
            Assert.willBeEqual(payload.members[0].user.createdAt, loadedChannel.lastActiveMembers.first?.userCreatedAt)
            Assert.willBeEqual(payload.members[0].user.updatedAt, loadedChannel.lastActiveMembers.first?.userUpdatedAt)
            Assert.willBeEqual(payload.members[0].user.lastActiveAt, loadedChannel.lastActiveMembers.first?.lastActiveAt)
            Assert.willBeEqual(payload.members[0].user.isOnline, loadedChannel.lastActiveMembers.first?.isOnline)
            Assert.willBeEqual(payload.members[0].user.isBanned, loadedChannel.lastActiveMembers.first?.isBanned)
            Assert.willBeEqual(payload.members[0].user.role, loadedChannel.lastActiveMembers.first?.userRole)
            Assert.willBeEqual(payload.members[0].user.extraData, loadedChannel.lastActiveMembers.first?.extraData)

            // Membership
            Assert.willBeEqual(payload.membership!.user.id, loadedChannel.membership?.id)

            // Messages
            Assert.willBeEqual(payload.messages[0].id, loadedChannel.latestMessages.first?.id)
            Assert.willBeEqual(payload.messages[0].type.rawValue, loadedChannel.latestMessages.first?.type.rawValue)
            Assert.willBeEqual(payload.messages[0].text, loadedChannel.latestMessages.first?.text)
            Assert.willBeEqual(payload.messages[0].updatedAt, loadedChannel.latestMessages.first?.updatedAt)
            Assert.willBeEqual(payload.messages[0].createdAt, loadedChannel.latestMessages.first?.createdAt)
            Assert.willBeEqual(payload.messages[0].deletedAt, loadedChannel.latestMessages.first?.deletedAt)
            Assert.willBeEqual(payload.messages[0].args, loadedChannel.latestMessages.first?.arguments)
            Assert.willBeEqual(payload.messages[0].command, loadedChannel.latestMessages.first?.command)
            Assert.willBeEqual(payload.messages[0].extraData, loadedChannel.latestMessages.first?.extraData)
            Assert.willBeEqual(payload.messages[0].isSilent, loadedChannel.latestMessages.first?.isSilent)
            Assert.willBeEqual(payload.messages[0].mentionedUsers.count, loadedChannel.latestMessages.first?.mentionedUsers.count)
            Assert.willBeEqual(payload.messages[0].parentId, loadedChannel.latestMessages.first?.parentMessageId)
            Assert.willBeEqual(payload.messages[0].reactionScores, loadedChannel.latestMessages.first?.reactionScores)
            Assert.willBeEqual(payload.messages[0].replyCount, loadedChannel.latestMessages.first?.replyCount)

            // Pinned Messages
            Assert.willBeEqual(payload.pinnedMessages[0].id, loadedChannel.pinnedMessages[0].id)
            Assert.willBeEqual(payload.pinnedMessages[0].pinned, loadedChannel.pinnedMessages[0].isPinned)
            Assert.willBeEqual(payload.pinnedMessages[0].pinnedAt, loadedChannel.pinnedMessages[0].pinDetails?.pinnedAt)
            Assert.willBeEqual(payload.pinnedMessages[0].pinExpires, loadedChannel.pinnedMessages[0].pinDetails?.expiresAt)
            Assert.willBeEqual(payload.pinnedMessages[0].pinnedBy?.id, loadedChannel.pinnedMessages[0].pinDetails?.pinnedBy.id)
            
            // Message user
            Assert.willBeEqual(payload.messages[0].user.id, loadedChannel.latestMessages.first?.author.id)
            Assert.willBeEqual(payload.messages[0].user.createdAt, loadedChannel.latestMessages.first?.author.userCreatedAt)
            Assert.willBeEqual(payload.messages[0].user.updatedAt, loadedChannel.latestMessages.first?.author.userUpdatedAt)
            Assert.willBeEqual(payload.messages[0].user.lastActiveAt, loadedChannel.latestMessages.first?.author.lastActiveAt)
            Assert.willBeEqual(payload.messages[0].user.isOnline, loadedChannel.latestMessages.first?.author.isOnline)
            Assert.willBeEqual(payload.messages[0].user.isBanned, loadedChannel.latestMessages.first?.author.isBanned)
            Assert.willBeEqual(payload.messages[0].user.role, loadedChannel.latestMessages.first?.author.userRole)
            Assert.willBeEqual(payload.messages[0].user.extraData, loadedChannel.latestMessages.first?.author.extraData)
            
            // Read
            Assert.willBeEqual(payload.channelReads[0].lastReadAt, loadedChannel.reads.first?.lastReadAt)
            Assert.willBeEqual(payload.channelReads[0].unreadMessagesCount, loadedChannel.reads.first?.unreadMessagesCount)
            Assert.willBeEqual(payload.channelReads[0].user.id, loadedChannel.reads.first?.user.id)
        }
    }

    func test_channelPayload_nilMembershipRemovesExistingMembership() throws {
        // Save a channel payload with 100 messages
        let channelId: ChannelId = .unique
        let payload = dummyPayload(with: channelId, numberOfMessages: 100)

        // Save a channel with membership to the DB
        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        var channel: ChatChannel? { database.viewContext.channel(cid: channelId)?.asModel() }
        XCTAssertNotNil(channel?.membership)

        // Simulate the channel was updated and it no longer has membership
        let payloadWithoutMembership = dummyPayload(with: channelId, includeMembership: false)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payloadWithoutMembership)
        }

        XCTAssertNil(channel?.membership)
    }

    func test_channelPayload_latestMessagesArePopulated() throws {
        // Save a channel payload with 100 messages
        let channelId: ChannelId = .unique
        let payload = dummyPayload(with: channelId, numberOfMessages: 100)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        // Assert only 25 messages is serialized in the model
        let channel: ChatChannel? = database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 25)
    }

    func test_channelPayload_pinnedMessagesArePopulated() throws {
        let channelId: ChannelId = .unique
        let pinnedMessages: [MessagePayload<NoExtraData>] = [
            .dummy(messageId: .unique, authorUserId: .unique, pinned: true),
            .dummy(messageId: .unique, authorUserId: .unique, pinned: true)
        ]
        let payload = dummyPayload(
            with: channelId,
            numberOfMessages: 100,
            pinnedMessages: pinnedMessages
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel? = database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.pinnedMessages.count, payload.pinnedMessages.count)
    }

    func test_channelPayload_oldestMessageAtIsUpdated() throws {
        let channelId: ChannelId = .unique
        let payload = dummyPayload(with: channelId, numberOfMessages: 20)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChannelDTO? = database.viewContext.channel(cid: channelId)
        XCTAssertEqual(channel?.oldestMessageAt, payload.messages.map(\.createdAt).min())
    }

    func test_channelPayload_whenMessagesNewerThanCurrentOldestMessage_oldestMessageAtIsNotUpdated() throws {
        let channelId: ChannelId = .unique
        let oldMessageCreatedAt = Date.unique
        let payload = dummyPayload(with: channelId, messages: [
            .dummy(messageId: .unique, authorUserId: .unique, createdAt: oldMessageCreatedAt)
        ])

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let newerMessageCreatedAt = oldMessageCreatedAt.addingTimeInterval(300)
        let newerPayload = dummyPayload(with: channelId, messages: [
            .dummy(messageId: .unique, authorUserId: .unique, createdAt: newerMessageCreatedAt)
        ])

        try database.writeSynchronously { session in
            try session.saveChannel(payload: newerPayload)
        }

        let channel: ChannelDTO? = database.viewContext.channel(cid: channelId)
        XCTAssertEqual(channel?.oldestMessageAt, oldMessageCreatedAt)
    }

    func test_channelPayload_truncatedMessagesAreIgnored() throws {
        // Save a channel payload with 100 messages
        let channelId: ChannelId = .unique
        let payload = dummyPayload(with: channelId, numberOfMessages: 100)

        try database.writeSynchronously { session in
            let channelDTO = try session.saveChannel(payload: payload)

            // Truncate the channel to leave only 10 newest messages
            let truncateDate = channelDTO.messages
                .sorted(by: { $0.createdAt < $1.createdAt })
                .dropLast(10)
                .last?
                .createdAt

            channelDTO.truncatedAt = truncateDate
        }

        // Assert only the 10 newest messages is serialized
        let channel: ChatChannel? = database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 10)
    }

    func test_channelPayload_pinnedMessagesOlderThanOldestMessageAtAreIgnored() throws {
        let channelId: ChannelId = .unique
        let oldPinnedMessage: MessagePayload<NoExtraData> = MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            createdAt: Date.distantPast,
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
            attachments: [],
            pinned: true
        )
        let payload = dummyPayload(with: channelId, numberOfMessages: 1, pinnedMessages: [oldPinnedMessage])

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel? = database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 1)
    }

    func test_channelPayload_pinnedMessagesNewerThanOldestMessageAreFetched() throws {
        let channelId: ChannelId = .unique
        let pinnedMessage: MessagePayload<NoExtraData> = MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            createdAt: Date(),
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
            attachments: [],
            pinned: true
        )
        let payload = dummyPayload(with: channelId, numberOfMessages: 1, pinnedMessages: [pinnedMessage])

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel? = database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 2)
    }
    
    func test_channelPayload_localCachingDefaults() throws {
        let memberLimit = Int.random(in: 1..<50)
        let watcherLimit = Int.random(in: 1..<50)
        let messagesLimit = Int.random(in: 1..<50)
        
        // Set `lastActiveMembersLimit` to the limit
        var caching = ChatClientConfig.LocalCaching()
        caching.chatChannel.lastActiveWatchersLimit = watcherLimit
        caching.chatChannel.lastActiveMembersLimit = memberLimit
        caching.chatChannel.latestMessagesLimit = messagesLimit

        let cid: ChannelId = .unique
        
        var database: DatabaseContainerMock! = DatabaseContainerMock(localCachingSettings: caching)
        
        // Create more entities than the limits
        let allMembers: [MemberPayload<NoExtraData>] = (0..<memberLimit * 2).map { _ in .dummy() }
        let allWatchers: [UserPayload<NoExtraData>] = (0..<watcherLimit * 2).map { _ in .dummy(userId: .unique) }
        let allMessages: [MessagePayload<NoExtraData>] = (0..<messagesLimit * 2)
            .map { _ in .dummy(messageId: .unique, authorUserId: .unique) }
        let payload = dummyPayload(with: cid, members: allMembers, watchers: allWatchers, messages: allMessages)
                
        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel = try XCTUnwrap(database.viewContext.channel(cid: cid)?.asModel())
        
        XCTAssertEqual(
            channel.lastActiveWatchers.map(\.id),
            allWatchers.sorted { $0.lastActiveAt! > $1.lastActiveAt! }
                .prefix(watcherLimit)
                .map(\.id)
        )

        XCTAssertEqual(
            channel.lastActiveMembers.map(\.id),
            allMembers.sorted { $0.user.lastActiveAt! > $1.user.lastActiveAt! }
                .prefix(memberLimit)
                .map(\.user.id)
        )
        
        AssertAsync.canBeReleased(&database)
    }

    func test_DTO_updateFromSamePayload_doNotProduceChanges() throws {
        // Arrange: Store random channel payload to db
        let channelId: ChannelId = .unique
        let payload = ChannelDetailPayload<NoExtraData>.dummy(cid: channelId)

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
            channelDTO.extraData = #"{"invalid": json}"#.data(using: .utf8)!
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
    
    func test_watchers_areCleared_onResetEphemeralValues() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        // Create user in the database
        try database.createUser(id: userId, extraData: .defaultValue)
        // Set created user as a watcher
        try database.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: cid))
            let member = try XCTUnwrap(session.user(id: userId))
            channel.watchers.insert(member)
            channel.watcherCount = Int64.random(in: 1...10)
        }
        
        // Load the channel
        var channel: ChatChannel {
            database.viewContext.channel(cid: cid)!.asModel()
        }
        
        // Assert channel's watchers are not empty, watcherCount not zero
        XCTAssertFalse(channel.lastActiveWatchers.isEmpty)
        XCTAssertNotEqual(channel.watcherCount, 0)
        
        // Simulate `resetEphemeralValues`
        database.resetEphemeralValues()
        
        // Assert channel's watchers are cleared, watcherCount zero'ed
        AssertAsync {
            Assert.willBeTrue(channel.lastActiveWatchers.isEmpty)
            Assert.willBeEqual(channel.watcherCount, 0)
        }
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
            createdAt: ChannelDTO_Tests.channelCreatedDate.addingTimeInterval(.random(in: 60...900_000)),
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

    var dummyPinnedMessage: MessagePayload<NoExtraData> {
        MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            // createAt should be lower than dummyMessage, so it does not come first in `latestMessages`
            createdAt: ChannelDTO_Tests.channelCreatedDate.addingTimeInterval(.random(in: 50...99)),
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
            attachments: [],
            pinned: true,
            pinnedBy: dummyUser,
            pinnedAt: .unique,
            pinExpires: .unique
        )
    }

    var dummyChannelRead: ChannelReadPayload<NoExtraData> {
        ChannelReadPayload(user: dummyCurrentUser, lastReadAt: Date(timeIntervalSince1970: 1), unreadMessagesCount: 10)
    }
    
    func dummyPayload(
        with channelId: ChannelId,
        numberOfMessages: Int = 1,
        members: [MemberPayload<NoExtraData>] = [.unique],
        watchers: [UserPayload<NoExtraData>]? = nil,
        includeMembership: Bool = true,
        messages: [MessagePayload<NoExtraData>]? = nil,
        pinnedMessages: [MessagePayload<NoExtraData>] = []
    ) -> ChannelPayload<NoExtraData> {
        let channelCreatedDate = Date.unique
        let lastMessageAt: Date? = Bool.random() ? channelCreatedDate.addingTimeInterval(.random(in: 100_000...900_000)) : nil

        var payloadMessages: [MessagePayload<NoExtraData>] = []
        if let messages = messages {
            payloadMessages = messages
        } else {
            for _ in 0..<numberOfMessages {
                payloadMessages += [dummyMessage]
            }
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
                    createdAt: ChannelDTO_Tests.channelCreatedDate,
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
                        createdAt: ChannelDTO_Tests.channelCreatedDate,
                        updatedAt: .unique
                    ),
                    isFrozen: true,
                    memberCount: 100,
                    team: .unique,
                    members: members,
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: watchers?.count ?? 1,
                watchers: watchers ?? [dummyUser],
                members: members,
                membership: includeMembership ? members.first : nil,
                messages: payloadMessages,
                pinnedMessages: pinnedMessages,
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
                        createdAt: ChannelDTO_Tests.channelCreatedDate,
                        updatedAt: .unique
                    ),
                    isFrozen: true,
                    memberCount: 100,
                    team: .unique,
                    members: nil,
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: 10,
                watchers: [dummyUser],
                members: [member],
                membership: member,
                messages: [dummyMessageWithNoExtraData],
                pinnedMessages: [dummyMessageWithNoExtraData],
                channelReads: [dummyChannelReadWithNoExtraData]
            )
        
        return payload
    }
}

private extension MemberPayload where ExtraData == NoExtraData {
    static var unique: MemberPayload<NoExtraData> {
        withLastActivity(at: .unique)
    }
    
    static func withLastActivity(at date: Date) -> MemberPayload<NoExtraData> {
        .init(
            user: .init(
                id: .unique,
                name: .unique,
                imageURL: nil,
                role: .admin,
                createdAt: .unique,
                updatedAt: .unique,
                lastActiveAt: date,
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
    }
}

private extension UserPayload where ExtraData == NoExtraData {
    static func withLastActivity(at date: Date) -> UserPayload<NoExtraData> {
        .init(
            id: .unique,
            name: .unique,
            imageURL: nil,
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: date,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: .defaultValue
        )
    }
}
