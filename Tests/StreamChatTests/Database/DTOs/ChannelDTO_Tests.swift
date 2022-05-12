//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }
    
    func test_saveChannel_whenThereIsNoPreview_updatesPreview() throws {
        // GIVEN
        let cid: ChannelId = .unique
        let emptyChannelPayload: ChannelPayload = .dummy(channel: .dummy(cid: cid))
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: emptyChannelPayload)
        }
        
        var channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertNil(channelDTO.previewMessage)
        
        // WHEN
        let previewMessage: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique
        )
        
        let channelPayload: ChannelPayload = .dummy(
            channel: emptyChannelPayload.channel,
            messages: [previewMessage]
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
        
        // THEN
        channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previewMessage.id)
    }

    func test_saveChannel_whenPayloadHasMessagesNewerThePreview_updatesPreview() throws {
        // GIVEN
        let previewMessage: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique
        )
        
        let channelPayload: ChannelPayload = .dummy(
            channel: .dummy(),
            messages: [previewMessage]
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
                
        // WHEN
        let newPreviewMessage: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(10)
        )
        
        let channelPayloadWithNewPreview: ChannelPayload = .dummy(
            channel: channelPayload.channel,
            messages: [newPreviewMessage]
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayloadWithNewPreview)
        }
        
        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channelPayload.channel.cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, newPreviewMessage.id)
    }
    
    func test_saveChannel_whenPayloadDoesNotHaveMessagesNewerThePreview_doesNotUpdatePreview() throws {
        // GIVEN
        let previewMessage: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique
        )
        
        let channelPayload: ChannelPayload = .dummy(
            channel: .dummy(),
            messages: [previewMessage]
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
                
        // WHEN
        let message: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(-10)
        )
        
        let channelPayloadWithoutNewPreview: ChannelPayload = .dummy(
            channel: channelPayload.channel,
            messages: [message]
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayloadWithoutNewPreview)
        }
        
        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channelPayload.channel.cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previewMessage.id)
    }
    
    func test_saveChannel_channelReadsAreSavedBeforeMessages() throws {
        // GIVEN
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let currentUserMember: MemberPayload = .dummy(user: currentUser)
        
        let anotherMember: MemberPayload = .dummy(user: .dummy(userId: .unique))
        let anotherMemberRead: ChannelReadPayload = .init(
            user: anotherMember.user,
            lastReadAt: .init(),
            unreadMessagesCount: 0
        )
        
        let ownMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: anotherMemberRead.lastReadAt.addingTimeInterval(-10)
        )
        
        let ownPinnedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: anotherMemberRead.lastReadAt.addingTimeInterval(-20),
            pinned: true,
            pinnedByUserId: anotherMember.user.id
        )
        
        let channelPayload: ChannelPayload = .dummy(
            channel: .dummy(),
            members: [currentUserMember, anotherMember],
            membership: currentUserMember,
            messages: [ownMessage],
            pinnedMessages: [ownPinnedMessage],
            channelReads: [anotherMemberRead]
        )

        // WHEN
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channelPayload)
        }
        
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: channelPayload.channel.cid)?.asModel()
        )
        let loadedOwnMessage = try XCTUnwrap(
            channel.latestMessages.first { $0.id == ownMessage.id }
        )
        let loadedOwnPinnedMessage = try XCTUnwrap(
            channel.pinnedMessages.first { $0.id == ownPinnedMessage.id }
        )
        
        // THEN
        //
        // Messages have reads.
        XCTAssertTrue(loadedOwnMessage.readBy.contains { $0.id == anotherMember.user.id })
        XCTAssertTrue(loadedOwnPinnedMessage.readBy.contains { $0.id == anotherMember.user.id })
    }
    
    func test_saveChannel_removesReadsNotPresentInPayload() throws {
        // GIVEN
        let read1 = ChannelReadPayload(
            user: .dummy(userId: .unique),
            lastReadAt: .init(),
            unreadMessagesCount: 0
        )
        
        var channelPayload: ChannelPayload = .dummy(
            channel: .dummy(),
            channelReads: [read1]
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
        
        // WHEN
        let read2 = ChannelReadPayload(
            user: .dummy(userId: .unique),
            lastReadAt: .init(),
            unreadMessagesCount: 0
        )
        
        channelPayload = .dummy(
            channel: channelPayload.channel,
            channelReads: [read2]
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
        
        // THEN
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: channelPayload.channel.cid)
        )
        let readToBeRemoved = database.viewContext.loadChannelRead(
            cid: channelPayload.channel.cid,
            userId: read1.user.id
        )
        let readToBeSaved = try XCTUnwrap(
            database.viewContext.loadChannelRead(
                cid: channelPayload.channel.cid,
                userId: read2.user.id
            )
        )
        
        XCTAssertEqual(channel.reads, [readToBeSaved])
        XCTAssertNil(readToBeRemoved)
    }
    
    func test_channelPayload_isStoredAndLoadedFromDB() throws {
        let channelId: ChannelId = .unique
    
        let messageCreatedAt: Date = .unique
        let message = dummyMessagePayload(createdAt: messageCreatedAt)
        
        // Pinned message should be older than `message` to ensure it's not returned first in `latestMessages`
        let pinnedMessage = dummyPinnedMessagePayload(createdAt: .unique(before: messageCreatedAt))
        
        let payload = dummyPayload(with: channelId, messages: [message], pinnedMessages: [pinnedMessage])
        
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
            
            Assert.willBeEqual(payload.isHidden, loadedChannel.isHidden)
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
            Assert.willBeEqual(payload.channel.config.quotesEnabled, loadedChannel.config.quotesEnabled)
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
            Assert.willBeEqual(payload.messages[0].reactionCounts, loadedChannel.latestMessages.first?.reactionCounts)
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
            
            // Truncated
            Assert.willBeEqual(payload.channel.truncatedAt, loadedChannel.truncatedAt)
        }
    }

    func test_defaultSortingAt_updates_whenLastMessageAtChanges() throws {
        let channelId: ChannelId = .unique
        
        try database.createChannel(cid: channelId)
        
        try database.writeSynchronously {
            let channel = try XCTUnwrap($0.channel(cid: channelId))
            channel.lastMessageAt = .unique(after: channel.lastMessageAt ?? channel.createdAt)
        }
        
        let channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.lastMessageAt, channel.defaultSortingAt)
    }

    func test_channelPayload_nilMembershipRemovesExistingMembership() throws {
        // Save a channel payload with 100 messages
        let channelId: ChannelId = .unique
        let payload = dummyPayload(with: channelId, numberOfMessages: 100)

        // Save a channel with membership to the DB
        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        var channel: ChatChannel? { try? database.viewContext.channel(cid: channelId)?.asModel() }
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
        let channel: ChatChannel? = try? database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 25)
    }

    func test_channelPayload_pinnedMessagesArePopulated() throws {
        let channelId: ChannelId = .unique
        let pinnedMessages: [MessagePayload] = [
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

        let channel: ChatChannel? = try? database.viewContext.channel(cid: channelId)?.asModel()
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
            // We're dropping 9 messages to fullfil the predicate: createdAt >= channel.truncatedAt"
            let truncateDate = channelDTO.messages
                .sorted(by: { $0.createdAt < $1.createdAt })
                .dropLast(9)
                .last?
                .createdAt

            channelDTO.truncatedAt = truncateDate
        }

        // Assert only the 10 newest messages is serialized
        let channel: ChatChannel? = try? database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 10)
    }

    func test_channelPayload_pinnedMessagesOlderThanOldestMessageAtAreIgnored() throws {
        let channelId: ChannelId = .unique
        let oldPinnedMessage: MessagePayload = MessagePayload(
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
            extraData: [:],
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            pinned: true
        )
        let payload = dummyPayload(with: channelId, numberOfMessages: 1, pinnedMessages: [oldPinnedMessage])

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel? = try? database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 1)
    }

    func test_channelPayload_pinnedMessagesNewerThanOldestMessageAreFetched() throws {
        let channelId: ChannelId = .unique
        let pinnedMessage: MessagePayload = MessagePayload(
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
            extraData: [:],
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            pinned: true
        )
        let payload = dummyPayload(with: channelId, numberOfMessages: 1, pinnedMessages: [pinnedMessage])

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel? = try? database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 2)
    }
    
    func test_channelPayload_localCachingDefaults() throws {
        // This is just a temp fix. The CI tends to fail if there are multiple Database instance alive at the same time.
        // -> CIS-756
        AssertAsync.canBeReleased(&database)
        
        let memberLimit = Int.random(in: 1..<50)
        let watcherLimit = Int.random(in: 1..<50)
        let messagesLimit = Int.random(in: 1..<50)
        
        // Set `lastActiveMembersLimit` to the limit
        var caching = ChatClientConfig.LocalCaching()
        caching.chatChannel.lastActiveWatchersLimit = watcherLimit
        caching.chatChannel.lastActiveMembersLimit = memberLimit
        caching.chatChannel.latestMessagesLimit = messagesLimit

        let cid: ChannelId = .unique
        
        database = DatabaseContainer_Spy(localCachingSettings: caching)
        
        // Create more entities than the limits
        let allMembers: [MemberPayload] = (0..<memberLimit * 2).map { _ in .dummy() }
        let allWatchers: [UserPayload] = (0..<watcherLimit * 2).map { _ in .dummy(userId: .unique) }
        let allMessages: [MessagePayload] = (0..<messagesLimit * 2)
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
    }
    
    func test_lastMessageFromCurrentUser() throws {
        let user: UserPayload = dummyCurrentUser
        let channelId: ChannelId = .unique
        let message1 = MessagePayload(
            id: .unique,
            type: .regular,
            user: user,
            createdAt: Date.distantPast,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            showReplyInChannel: true,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 1,
            extraData: [:],
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            pinned: false
        )
        
        let message2 = MessagePayload(
            id: .unique,
            type: .regular,
            user: user,
            createdAt: Date(),
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            showReplyInChannel: false,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 0,
            extraData: [:],
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            pinned: false
        )
        
        let channel = dummyPayload(with: channelId, messages: [message1, message2])
        
        try! database.createCurrentUser(id: user.id)
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        
        guard let channel: ChatChannel = database.viewContext.channel(cid: channelId)?.asModel(),
              let lastMessageFromCurrentUser = channel.lastMessageFromCurrentUser else {
            XCTFail("\(#file), \(#function), \(#line) There should be a valid channel")
            return
        }
        
        XCTAssertEqual(lastMessageFromCurrentUser.text, message2.text)
    }
    
    func test_lastMessageFromCurrentUser_whenLastMessageIsThreadReply() throws {
        let user: UserPayload = dummyCurrentUser
        let channelId: ChannelId = .unique
        let mainMessageId: String = .unique
        let mainMessage = MessagePayload(
            id: mainMessageId,
            type: .regular,
            user: user,
            createdAt: Date.distantPast,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: true,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 1,
            extraData: [:],
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            pinned: false
        )
        
        let threadMessage = MessagePayload(
            id: .unique,
            type: .regular,
            user: user,
            createdAt: Date(),
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: mainMessageId,
            showReplyInChannel: false,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 0,
            extraData: [:],
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            pinned: false
        )
        
        let channel = dummyPayload(with: channelId, messages: [mainMessage, threadMessage])
        
        try! database.createCurrentUser(id: user.id)
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        
        guard let channel: ChatChannel = database.viewContext.channel(cid: channelId)?.asModel(),
              let lastMessageFromCurrentUser = channel.lastMessageFromCurrentUser else {
            XCTFail("\(#file), \(#function), \(#line) There should be a valid channel")
            return
        }
        
        XCTAssertEqual(lastMessageFromCurrentUser.text, threadMessage.text)
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
            channelDTO.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }
        
        // Load the channel from the db and check the fields are correct
        let loadedChannel: ChatChannel? = try? database.viewContext.channel(cid: channelId)?.asModel()
        
        XCTAssertEqual(loadedChannel?.extraData, [:])
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
        let queryWithDefaultSorting = ChannelListQuery(filter: filter)
        let queryWithUpdatedAtSorting = ChannelListQuery(filter: filter, sort: [.init(key: .updatedAt, isAscending: false)])

        // Create dummy channels payloads with ids: a, b, c, d.
        let payload1 = dummyPayload(with: try! .init(cid: "a:a"), numberOfMessages: 0)
        let payload2 = dummyPayload(with: try! .init(cid: "a:b"), numberOfMessages: 0)
        let payload3 = dummyPayload(with: try! .init(cid: "a:c"), numberOfMessages: 0)
        let payload4 = dummyPayload(with: try! .init(cid: "a:d"), numberOfMessages: 0)

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

    func test_channelListFetchRequest_ignoresHiddenChannels() throws {
        // Create a dummy query
        let query = ChannelListQuery(filter: .exists(.cid))

        // Create a couple of channels
        let visibleCid1: ChannelId = .unique
        let visibleCid2: ChannelId = .unique

        try database.writeSynchronously { session in
            // Save the non-hidden channel
            try session.saveChannel(payload: self.dummyPayload(with: visibleCid1), query: query)

            // Save a channel with `isHidden` = false -> should be visible
            let visible = try session.saveChannel(
                payload: self.dummyPayload(with: visibleCid2, numberOfMessages: 10),
                query: query
            )
            visible.isHidden = false

            // Save a channel with `isHidden` = `true` -> should NOT be visible
            let hidden1 = try session.saveChannel(
                payload: self.dummyPayload(with: .unique, numberOfMessages: 10),
                query: query
            )
            hidden1.isHidden = true
        }

        let fetchRequest = ChannelDTO.channelListFetchRequest(query: query)
        let loadedChannels: [ChannelDTO] = try database.viewContext.fetch(fetchRequest)

        XCTAssertEqual(loadedChannels.count, 2)
        XCTAssertTrue(loadedChannels.contains { $0.cid == visibleCid1.rawValue })
        XCTAssertTrue(loadedChannels.contains { $0.cid == visibleCid2.rawValue })
    }
    
    func test_channelUnreadCount_calculatedCorrectly() throws {
        // GIVEN
        let currentUserPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)

        let currentUserChannelReadPayload: ChannelReadPayload = .init(
            user: currentUserPayload,
            lastReadAt: .init(),
            unreadMessagesCount: 0
        )

        let messageMentioningCurrentUser: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: currentUserChannelReadPayload.lastReadAt.addingTimeInterval(5),
            mentionedUsers: [currentUserPayload]
        )

        let channelPayload = ChannelPayload(
            channel: .dummy(cid: .unique),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserPayload)],
            membership: .dummy(user: currentUserPayload),
            messages: [messageMentioningCurrentUser],
            pinnedMessages: [],
            channelReads: [currentUserChannelReadPayload],
            isHidden: false
        )

        let unreadMessages = 5

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUserPayload)
            try session.saveChannel(payload: channelPayload)

            let read = try XCTUnwrap(
                session.loadChannelRead(cid: channelPayload.channel.cid, userId: currentUserPayload.id)
            )
            read.unreadMessageCount = Int32(unreadMessages)
        }

        // WHEN
        let unreadCount = try XCTUnwrap(
            database.viewContext.channel(cid: channelPayload.channel.cid)?.asModel().unreadCount
        )
        
        // THEN
        XCTAssertEqual(unreadCount.messages, unreadMessages)
        XCTAssertEqual(unreadCount.mentions, 1)
    }
    
    func test_typingUsers_areCleared_onResetEphemeralValues() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        // Create user in the database
        try database.createUser(id: userId)
        // Set created user as a typing user
        try database.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: cid))
            let user = try XCTUnwrap(session.user(id: userId))
            channel.currentlyTypingUsers.insert(user)
        }
        
        // Load the channel
        func getChannel() throws -> ChatChannel { try channel(with: cid) }

        // Assert channel's currentlyTypingUsers are not empty
        try XCTAssertFalse(getChannel().currentlyTypingUsers.isEmpty)
        
        // Simulate `resetEphemeralValues`
        database.resetEphemeralValues()
        
        // Assert channel's currentlyTypingUsers are cleared
        AssertAsync.willBeTrue((try? getChannel().currentlyTypingUsers.isEmpty) ?? false)
    }
    
    func test_createFromDTO_handlesExtraDataCorrectlyWhenPresent() throws {
        let cid: ChannelId = .unique

        let extraData: [String: RawJSON] = ["k": .string("v")]
        try database.createChannel(cid: cid, channelExtraData: extraData)
        let channel = try self.channel(with: cid)
        XCTAssertEqual(channel.extraData, ["k": .string("v")])
    }

    func test_watchers_areCleared_onResetEphemeralValues() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        // Create user in the database
        try database.createUser(id: userId, extraData: [:])
        // Set created user as a watcher
        try database.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: cid))
            let member = try XCTUnwrap(session.user(id: userId))
            channel.watchers.insert(member)
            channel.watcherCount = Int64.random(in: 1...10)
        }
        
        // Load the channel
        func getChannel() throws -> ChatChannel { try channel(with: cid) }

        // Assert channel's watchers are not empty, watcherCount not zero
        try XCTAssertFalse(getChannel().lastActiveWatchers.isEmpty)
        try XCTAssertNotEqual(getChannel().watcherCount, 0)
        
        // Simulate `resetEphemeralValues`
        database.resetEphemeralValues()
        
        // Assert channel's watchers are cleared, watcherCount zero'ed
        AssertAsync {
            Assert.willBeTrue((try? getChannel().lastActiveWatchers.isEmpty) ?? false)
            Assert.willBeEqual(try? getChannel().watcherCount, 0)
        }
    }

    func test_channelConfigCommands_whenConvertedToDTO_thenPreserveOrder() {
        // Given
        let config = ChannelConfig.mock(
            commands: [
                .init(name: "giphy", description: "", set: "", args: ""),
                .init(name: "workout", description: "", set: "", args: ""),
                .init(name: "location", description: "", set: "", args: "")
            ]
        )

        // When
        let dto = config.asDTO(context: database.viewContext, cid: "test")

        // Then
        let actual = dto.commands.compactMap { $0 as? CommandDTO }.map(\.name)
        let expected = ["giphy", "workout", "location"]
        XCTAssertEqual(actual, expected)
    }
    
    func test_asModel_populatesPreviewMessage() throws {
        // GIVEN
        let channelPayload: ChannelPayload = .dummy()
        
        let previewMessagePayload: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            text: .unique
        )
        
        try database.writeSynchronously { session in
            let chanenlDTO = try session.saveChannel(payload: channelPayload)
            
            chanenlDTO.previewMessage = try session.saveMessage(
                payload: previewMessagePayload,
                channelDTO: chanenlDTO,
                syncOwnReactions: false
            )
        }

        // WHEN
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: channelPayload.channel.cid)?.asModel()
        )
        
        // THEN
        let previewMessage = try XCTUnwrap(channel.previewMessage)
        XCTAssertEqual(previewMessage.text, previewMessagePayload.text)
    }
    
    func test_asModel_populatesLatestMessage() throws {
        // GIVEN
        database = DatabaseContainer_Spy(
            kind: .inMemory,
            localCachingSettings: .init(
                chatChannel: .init(
                    lastActiveWatchersLimit: 0,
                    lastActiveMembersLimit: 0,
                    latestMessagesLimit: 3
                )
            ),
            deletedMessagesVisibility: .visibleForCurrentUser,
            shouldShowShadowedMessages: true
        )
        
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .admin)
        let anotherUser: UserPayload = .dummy(userId: .unique)

        let cid: ChannelId = .unique
       
        let message1: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            text: "message1",
            createdAt: .init(),
            cid: cid
        )
        
        let deletedMessageFromCurrentUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            text: "deletedMessageFromCurrentUser",
            createdAt: message1.createdAt.addingTimeInterval(-1),
            deletedAt: .init(),
            cid: cid
        )
        
        let deletedMessageFromAnotherUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: "deletedMessageFromAnotherUser",
            createdAt: deletedMessageFromCurrentUser.createdAt.addingTimeInterval(-1),
            deletedAt: .init(),
            cid: cid
        )
        
        let shadowedMessageFromAnotherUser: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: "shadowedMessageFromAnotherUser",
            createdAt: deletedMessageFromAnotherUser.createdAt.addingTimeInterval(-1),
            cid: cid,
            isShadowed: true
        )
        
        let message2: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: "message2",
            createdAt: shadowedMessageFromAnotherUser.createdAt.addingTimeInterval(-1),
            cid: cid
        )
        
        let channelPayload: ChannelPayload = .dummy(
            channel: .dummy(cid: cid),
            messages: [
                message1,
                deletedMessageFromCurrentUser,
                deletedMessageFromAnotherUser,
                shadowedMessageFromAnotherUser,
                message2
            ]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)?.asModel()
        )
        
        // THEN
        XCTAssertEqual(
            Set(channel.latestMessages.map(\.id)),
            Set([message1.id, deletedMessageFromCurrentUser.id, shadowedMessageFromAnotherUser.id])
        )
    }
}

private extension ChannelDTO_Tests {
    func channel(with cid: ChannelId) throws -> ChatChannel {
        try XCTUnwrap(database.viewContext.channel(cid: cid)).asModel()
    }
}
