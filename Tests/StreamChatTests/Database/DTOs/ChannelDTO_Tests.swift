//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        let emptyChannelPayload: ChannelStateResponse = .dummy(channel: .dummy(cid: cid))

        try database.writeSynchronously { session in
            try session.saveChannel(payload: emptyChannelPayload)
        }

        var channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertNil(channelDTO.previewMessage)

        // WHEN
        let previewMessage: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique
        )

        let channelPayload: ChannelStateResponse = .dummy(
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
        let previewMessage: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique
        )
        let cid = ChannelId.unique

        let channelPayload: ChannelStateResponse = .dummy(
            channel: .dummy(cid: cid),
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let newPreviewMessage: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(10)
        )

        let channelPayloadWithNewPreview: ChannelStateResponse = .dummy(
            channel: channelPayload.channel,
            messages: [newPreviewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayloadWithNewPreview)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, newPreviewMessage.id)
    }

    func test_saveChannel_whenPayloadDoesNotHaveMessagesNewerThePreview_doesNotUpdatePreview() throws {
        // GIVEN
        let previewMessage: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique
        )

        let cid = ChannelId.unique
        let channelPayload: ChannelStateResponse = .dummy(
            channel: .dummy(cid: cid),
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let message: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(-10)
        )

        let channelPayloadWithoutNewPreview: ChannelStateResponse = .dummy(
            channel: channelPayload.channel,
            messages: [message]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayloadWithoutNewPreview)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previewMessage.id)
    }

    func test_saveChannel_channelReadsAreSavedBeforeMessages() throws {
        // GIVEN
        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let currentUserMember: ChannelMember = .dummy(user: currentUser.toUser)

        let anotherMember: ChannelMember = .dummy(user: .dummy(userId: .unique))
        let anotherMemberRead = Read(
            lastRead: Date(),
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: .dummy(userId: anotherMember.user!.id)
        )

        let ownMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: anotherMemberRead.lastRead.addingTimeInterval(-10)
        )

        let ownPinnedMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: anotherMemberRead.lastRead.addingTimeInterval(-20),
            pinned: true,
            pinnedByUserId: anotherMember.user!.id
        )

        let cid = ChannelId.unique
        let channelPayload = ChannelStateResponse.dummy(
            cid: cid,
            channel: .dummy(),
            members: [currentUserMember, anotherMember],
            messages: [ownMessage],
            reads: [anotherMemberRead],
            membership: currentUserMember
        )

        // WHEN
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channelPayload)
        }

        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)?.asModel()
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
        XCTAssertTrue(loadedOwnMessage.readBy.contains { $0.id == anotherMember.user!.id })
        XCTAssertTrue(loadedOwnPinnedMessage.readBy.contains { $0.id == anotherMember.user!.id })
    }

    func test_saveChannel_removesReadsNotPresentInPayload() throws {
        // GIVEN
        let read1 = Read(
            lastRead: .unique,
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: .dummy(userId: .unique)
        )

        var channelPayload: ChannelStateResponse = .dummy(
            channel: .dummy(),
            reads: [read1]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let read2 = Read(
            lastRead: .unique,
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: .dummy(userId: .unique)
        )

        channelPayload = .dummy(
            channel: channelPayload.channel,
            reads: [read2]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // THEN
        let cid = try ChannelId(cid: channelPayload.channel!.cid)
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        let readToBeRemoved = database.viewContext.loadChannelRead(
            cid: cid,
            userId: read1.user!.id
        )
        let readToBeSaved = try XCTUnwrap(
            database.viewContext.loadChannelRead(
                cid: cid,
                userId: read2.user!.id
            )
        )

        XCTAssertEqual(channel.reads, [readToBeSaved])
        XCTAssertNil(readToBeRemoved)
    }

    func test_saveChannel_updatesTruncatedAt_whenExistingIsNil() throws {
        let channelId: ChannelId = .unique
        let originalPayload = ChannelResponse.dummy(cid: channelId, truncatedAt: nil)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: originalPayload, query: nil, cache: nil)
        }

        XCTAssertNil(database.viewContext.channel(cid: channelId)?.truncatedAt)

        let newTruncatedAt = Date().addingTimeInterval(1200)
        let newPayload = ChannelResponse.dummy(cid: channelId, truncatedAt: newTruncatedAt)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: newPayload, query: nil, cache: nil)
        }

        XCTAssertEqual(database.viewContext.channel(cid: channelId)?.truncatedAt, newTruncatedAt.bridgeDate)
    }

    func test_saveChannel_updatesTruncatedAt_whenItsOlderThanExisting() throws {
        let channelId: ChannelId = .unique
        let originalTruncatedAt = Date()
        let originalPayload = ChannelResponse.dummy(cid: channelId, truncatedAt: originalTruncatedAt)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: originalPayload, query: nil, cache: nil)
        }

        XCTAssertEqual(database.viewContext.channel(cid: channelId)?.truncatedAt, originalTruncatedAt.bridgeDate)

        let newTruncatedAt = Date().addingTimeInterval(1200)
        let newPayload = ChannelResponse.dummy(cid: channelId, truncatedAt: newTruncatedAt)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: newPayload, query: nil, cache: nil)
        }

        XCTAssertEqual(database.viewContext.channel(cid: channelId)?.truncatedAt, newTruncatedAt.bridgeDate)
    }

    func test_saveChannel_doesNotUpdateTruncatedAt_whenItsEarlierThanExisting() throws {
        let channelId: ChannelId = .unique
        let originalTruncatedAt = Date().addingTimeInterval(1200)
        let originalPayload = ChannelResponse.dummy(cid: channelId, truncatedAt: originalTruncatedAt)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: originalPayload, query: nil, cache: nil)
        }

        XCTAssertEqual(database.viewContext.channel(cid: channelId)?.truncatedAt, originalTruncatedAt.bridgeDate)

        let newTruncatedAt = Date()
        let newPayload = ChannelResponse.dummy(cid: channelId, truncatedAt: newTruncatedAt)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: newPayload, query: nil, cache: nil)
        }

        XCTAssertEqual(database.viewContext.channel(cid: channelId)?.truncatedAt, originalTruncatedAt.bridgeDate)
    }

    func test_saveChannel_whenChannelTruncated_shouldEraseNewestMessageAt() throws {
        let channelId: ChannelId = .unique
        let originalPayload = ChannelResponse.dummy(cid: channelId, truncatedAt: nil)
        try database.writeSynchronously { session in
            let channel = try session.saveChannel(payload: originalPayload, query: nil, cache: nil)
            channel.newestMessageAt = .unique
        }
        var channelDTO: ChannelDTO? {
            database.viewContext.channel(cid: channelId)
        }

        XCTAssertNotNil(channelDTO?.newestMessageAt)

        let newTruncatedAt = Date().addingTimeInterval(1200)
        let newPayload = ChannelResponse.dummy(cid: channelId, truncatedAt: newTruncatedAt)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: newPayload, query: nil, cache: nil)
        }

        XCTAssertNil(channelDTO?.newestMessageAt)
        XCTAssertNotNil(channelDTO)
    }

    func test_channelPayload_isStoredAndLoadedFromDB() throws {
        let channelId: ChannelId = .unique

        let messageCreatedAt: Date = .unique
        let message = dummyMessagePayload(createdAt: messageCreatedAt)

        // Pinned message should be older than `message` to ensure it's not returned first in `latestMessages`
        let pinnedMessage = dummyPinnedMessagePayload(createdAt: .unique(before: messageCreatedAt))

        let payload = dummyPayload(
            with: channelId,
            messages: [message],
            pinnedMessages: [pinnedMessage],
            ownCapabilities: ["join-channel", "delete-channel"]
        )

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

            Assert.willBeEqual(payload.hidden, loadedChannel.isHidden)
            Assert.willBeEqual(payload.watcherCount, loadedChannel.watcherCount)
            Assert.willBeEqual(Set(payload.watchers?.map(\.id) ?? []), Set(loadedChannel.lastActiveWatchers.map(\.id)))
//            Assert.willBeEqual(payload.channel.name, loadedChannel.name)
//            Assert.willBeEqual(payload.channel.imageURL, loadedChannel.imageURL)
            Assert.willBeEqual(payload.channel?.memberCount, loadedChannel.memberCount)
            Assert.willBeEqual(payload.channel?.custom, loadedChannel.extraData)
            Assert.willBeEqual(payload.channel?.type, loadedChannel.type.rawValue)
            Assert.willBeEqual(payload.channel?.lastMessageAt, loadedChannel.lastMessageAt)
            Assert.willBeEqual(payload.channel?.createdAt, loadedChannel.createdAt)
            Assert.willBeEqual(payload.channel?.updatedAt, loadedChannel.updatedAt)
            Assert.willBeEqual(payload.channel?.deletedAt, loadedChannel.deletedAt)
            Assert.willBeEqual(payload.channel?.cooldown, loadedChannel.cooldownDuration)
            Assert.willBeEqual(payload.channel?.team, loadedChannel.team)

            // Config
            Assert.willBeEqual(payload.channel?.config?.reactions, loadedChannel.config.reactions)
            Assert.willBeEqual(payload.channel?.config?.typingEvents, loadedChannel.config.typingEvents)
            Assert.willBeEqual(payload.channel?.config?.readEvents, loadedChannel.config.readEvents)
            Assert.willBeEqual(payload.channel?.config?.connectEvents, loadedChannel.config.connectEvents)
            Assert.willBeEqual(payload.channel?.config?.uploads, loadedChannel.config.uploads)
            Assert.willBeEqual(payload.channel?.config?.replies, loadedChannel.config.replies)
            Assert.willBeEqual(payload.channel?.config?.quotes, loadedChannel.config.quotes)
            Assert.willBeEqual(payload.channel?.config?.search, loadedChannel.config.search)
            Assert.willBeEqual(payload.channel?.config?.mutes, loadedChannel.config.mutes)
            Assert.willBeEqual(payload.channel?.config?.urlEnrichment, loadedChannel.config.urlEnrichment)
            Assert.willBeEqual(payload.channel?.config?.messageRetention, loadedChannel.config.messageRetention)
            Assert.willBeEqual(payload.channel?.config?.maxMessageLength, loadedChannel.config.maxMessageLength)
            Assert.willBeEqual(payload.channel?.config?.commands.map(\.!.name), loadedChannel.config.commands)
            Assert.willBeEqual(payload.channel?.config?.createdAt, loadedChannel.config.createdAt)
            Assert.willBeEqual(payload.channel?.config?.updatedAt, loadedChannel.config.updatedAt)

            // Own Capabilities
            Assert.willBeEqual(payload.channel?.ownCapabilities, ["join-channel", "delete-channel"])

            // Creator
            Assert.willBeEqual(payload.channel?.createdBy?.id, loadedChannel.createdBy?.id)
            Assert.willBeEqual(payload.channel?.createdBy?.createdAt, loadedChannel.createdBy?.userCreatedAt)
            Assert.willBeEqual(payload.channel?.createdBy?.updatedAt, loadedChannel.createdBy?.userUpdatedAt)
            Assert.willBeEqual(payload.channel?.createdBy?.lastActive, loadedChannel.createdBy?.lastActiveAt)
            Assert.willBeEqual(payload.channel?.createdBy?.online, loadedChannel.createdBy?.isOnline)
            Assert.willBeEqual(payload.channel?.createdBy?.banned, loadedChannel.createdBy?.isBanned)
            Assert.willBeEqual(payload.channel?.createdBy?.role, loadedChannel.createdBy?.userRole.rawValue)
            Assert.willBeEqual(payload.channel?.createdBy?.custom, loadedChannel.createdBy?.extraData)

            // Members
            Assert.willBeEqual(payload.members[0]?.channelRole, loadedChannel.lastActiveMembers.first?.memberRole.rawValue)
            Assert.willBeEqual(payload.members[0]?.createdAt, loadedChannel.lastActiveMembers.first?.memberCreatedAt)
            Assert.willBeEqual(payload.members[0]?.updatedAt, loadedChannel.lastActiveMembers.first?.memberUpdatedAt)

            Assert.willBeEqual(payload.members[0]?.user?.id, loadedChannel.lastActiveMembers.first?.id)
            Assert.willBeEqual(payload.members[0]?.user?.createdAt, loadedChannel.lastActiveMembers.first?.userCreatedAt)
            Assert.willBeEqual(payload.members[0]?.user?.updatedAt, loadedChannel.lastActiveMembers.first?.userUpdatedAt)
            Assert.willBeEqual(payload.members[0]?.user?.lastActive, loadedChannel.lastActiveMembers.first?.lastActiveAt)
            Assert.willBeEqual(payload.members[0]?.user?.online, loadedChannel.lastActiveMembers.first?.isOnline)
            Assert.willBeEqual(payload.members[0]?.user?.banned, loadedChannel.lastActiveMembers.first?.isBanned)
            Assert.willBeEqual(payload.members[0]?.user?.role, loadedChannel.lastActiveMembers.first?.userRole.rawValue)
            Assert.willBeEqual(payload.members[0]?.user?.custom, loadedChannel.lastActiveMembers.first?.extraData)

            // Membership
            Assert.willBeEqual(payload.membership?.user?.id, loadedChannel.membership?.id)

            // Messages
            Assert.willBeEqual(payload.messages[0].id, loadedChannel.latestMessages.first?.id)
            Assert.willBeEqual(payload.messages[0].type, loadedChannel.latestMessages.first?.type.rawValue)
            Assert.willBeEqual(payload.messages[0].text, loadedChannel.latestMessages.first?.text)
            Assert.willBeEqual(payload.messages[0].updatedAt, loadedChannel.latestMessages.first?.updatedAt)
            Assert.willBeEqual(payload.messages[0].createdAt, loadedChannel.latestMessages.first?.createdAt)
            Assert.willBeEqual(payload.messages[0].deletedAt, loadedChannel.latestMessages.first?.deletedAt)
//            Assert.willBeEqual(payload.messages[0].args, loadedChannel.latestMessages.first?.arguments)
            Assert.willBeEqual(payload.messages[0].command, loadedChannel.latestMessages.first?.command)
            Assert.willBeEqual(payload.messages[0].custom, loadedChannel.latestMessages.first?.extraData)
            Assert.willBeEqual(payload.messages[0].silent, loadedChannel.latestMessages.first?.isSilent)
            Assert.willBeEqual(payload.messages[0].mentionedUsers.count, loadedChannel.latestMessages.first?.mentionedUsers.count)
            Assert.willBeEqual(payload.messages[0].parentId, loadedChannel.latestMessages.first?.parentMessageId)
            Assert.willBeEqual(payload.messages[0].reactionScores, loadedChannel.latestMessages.first?.reactionScores.mapKeys(\.rawValue))
            Assert.willBeEqual(payload.messages[0].reactionCounts, loadedChannel.latestMessages.first?.reactionCounts.mapKeys(\.rawValue))
            Assert.willBeEqual(payload.messages[0].replyCount, loadedChannel.latestMessages.first?.replyCount)

            // Pinned Messages
            Assert.willBeEqual(payload.pinnedMessages.first?.id, loadedChannel.pinnedMessages.first?.id)
            Assert.willBeEqual(payload.pinnedMessages.first?.pinned, loadedChannel.pinnedMessages.first?.isPinned)
            Assert.willBeEqual(payload.pinnedMessages.first?.pinnedAt, loadedChannel.pinnedMessages.first?.pinDetails?.pinnedAt)
            Assert.willBeEqual(payload.pinnedMessages.first?.pinExpires, loadedChannel.pinnedMessages.first?.pinDetails?.expiresAt)
            Assert.willBeEqual(payload.pinnedMessages.first?.pinnedBy?.id, loadedChannel.pinnedMessages.first?.pinDetails?.pinnedBy.id)

            // Message user
            Assert.willBeEqual(payload.messages[0].user?.id, loadedChannel.latestMessages.first?.author.id)
            Assert.willBeEqual(payload.messages[0].user?.createdAt, loadedChannel.latestMessages.first?.author.userCreatedAt)
            Assert.willBeEqual(payload.messages[0].user?.updatedAt, loadedChannel.latestMessages.first?.author.userUpdatedAt)
            Assert.willBeEqual(payload.messages[0].user?.lastActive, loadedChannel.latestMessages.first?.author.lastActiveAt)
            Assert.willBeEqual(payload.messages[0].user?.online, loadedChannel.latestMessages.first?.author.isOnline)
            Assert.willBeEqual(payload.messages[0].user?.banned, loadedChannel.latestMessages.first?.author.isBanned)
            Assert.willBeEqual(payload.messages[0].user?.role, loadedChannel.latestMessages.first?.author.userRole.rawValue)
            Assert.willBeEqual(payload.messages[0].user?.custom, loadedChannel.latestMessages.first?.author.extraData)

            // Read
            Assert.willBeEqual(payload.read?[0]?.lastRead, loadedChannel.reads.first?.lastReadAt)
            Assert.willBeEqual(payload.read?[0]?.unreadMessages, loadedChannel.reads.first?.unreadMessagesCount)
            Assert.willBeEqual(payload.read?[0]?.user?.id, loadedChannel.reads.first?.user.id)

            // Truncated
            Assert.willBeEqual(payload.channel?.truncatedAt, loadedChannel.truncatedAt)
        }
    }

    func test_defaultSortingAt_shouldBeEqualToLastMessageAt() throws {
        let channelId: ChannelId = .unique
        try database.createChannel(cid: channelId)
        try database.writeSynchronously {
            let channel = try XCTUnwrap($0.channel(cid: channelId))
            channel.lastMessageAt = .unique
        }

        let channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.defaultSortingAt, channel.lastMessageAt)
    }

    func test_defaultSortingAt_whenMissingLastMessageAt_shouldBeEqualToCreatedAt() throws {
        let channelId: ChannelId = .unique
        try database.createChannel(cid: channelId)
        try database.writeSynchronously {
            let channel = try XCTUnwrap($0.channel(cid: channelId))
            channel.createdAt = .unique
            channel.lastMessageAt = nil
        }

        let channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.defaultSortingAt, channel.createdAt)
    }

    func test_defaultSortingAt_whenLastMessageAtEqualDistantPast_shouldBeEqualToCreatedAt() throws {
        let channelId: ChannelId = .unique
        try database.createChannel(cid: channelId)
        try database.writeSynchronously {
            let channel = try XCTUnwrap($0.channel(cid: channelId))
            channel.createdAt = .unique
            channel.lastMessageAt = .distantPast.bridgeDate
        }

        let channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.defaultSortingAt, channel.createdAt)
    }

    func test_channelPayload_nilMembershipRemovesExistingMembership() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
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
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
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
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        let channelId: ChannelId = .unique
        let pinnedMessages: [Message] = [
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
        XCTAssertNearlySameDate(channel?.oldestMessageAt?.bridgeDate, payload.messages.map(\.createdAt).min())
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
        XCTAssertEqual(channel?.oldestMessageAt?.bridgeDate, oldMessageCreatedAt)
    }
    
    func test_channelPayload_truncatedMessagesAreIgnored() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        // Save a channel payload with 100 messages
        let channelId: ChannelId = .unique
        let payload = dummyPayload(with: channelId, numberOfMessages: 100)

        try database.writeSynchronously { session in
            let channelDTO = try session.saveChannel(payload: payload)

            // Truncate the channel to leave only 10 newest messages
            // We're dropping 9 messages to fullfil the predicate: createdAt >= channel.truncatedAt"
            let truncateDate = channelDTO.messages
                .sorted(by: { $0.createdAt.bridgeDate < $1.createdAt.bridgeDate })
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
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        let channelId: ChannelId = .unique
        let oldPinnedMessage = Message.dummy(authorUserId: dummyUser.id, mentionedUsers: [dummyCurrentUser.toUser])
        let payload = dummyPayload(with: channelId, numberOfMessages: 1, pinnedMessages: [oldPinnedMessage])

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel? = try? database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 1)
    }

    func test_channelPayload_pinnedMessagesNewerThanOldestMessageAreFetched() throws {
        let channelId: ChannelId = .unique
        let pinnedMessage = Message.dummy(authorUserId: dummyUser.id, mentionedUsers: [dummyCurrentUser.toUser])
        let payload = dummyPayload(with: channelId, numberOfMessages: 1, pinnedMessages: [pinnedMessage])

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel? = try? database.viewContext.channel(cid: channelId)?.asModel()
        XCTAssertEqual(channel?.latestMessages.count, 2)
    }

    func test_channelPayload_localCachingDefaults() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
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
        let allMembers: [ChannelMember] = (0..<memberLimit * 2).map { _ in .dummy() }
        let allWatchers: [UserObject] = (0..<watcherLimit * 2).map { _ in .dummy(userId: .unique) }
        let allMessages: [Message] = (0..<messagesLimit * 2)
            .map { _ in .dummy(messageId: .unique, authorUserId: .unique) }
        let payload = dummyPayload(with: cid, members: allMembers, watchers: allWatchers, messages: allMessages)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let channel: ChatChannel = try XCTUnwrap(database.viewContext.channel(cid: cid)?.asModel())

        XCTAssertEqual(
            channel.lastActiveWatchers.map(\.id),
            allWatchers.sorted { $0.lastActive! > $1.lastActive! }
                .prefix(watcherLimit)
                .map(\.id)
        )

        XCTAssertEqual(
            channel.lastActiveMembers.map(\.id),
            allMembers.sorted { $0.user!.lastActive! > $1.user!.lastActive! }
                .prefix(memberLimit)
                .map(\.user!.id)
        )
    }

    func test_lastMessageFromCurrentUser() throws {
        let user: OwnUser = dummyCurrentUser
        let channelId: ChannelId = .unique
        let message1: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: user.id,
            createdAt: Date.distantPast
        )

        let message2: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: user.id,
            createdAt: Date()
        )

        let message3: Message = .dummy(
            type: .ephemeral,
            messageId: .unique,
            authorUserId: user.id,
            createdAt: Date()
        )

        let channel = dummyPayload(with: channelId, messages: [message1, message2, message3])

        try! database.createCurrentUser(id: user.id)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        guard let channel: ChatChannel = try? database.viewContext.channel(cid: channelId)?.asModel(),
              let lastMessageFromCurrentUser = channel.lastMessageFromCurrentUser else {
            XCTFail("\(#file), \(#function), \(#line) There should be a valid channel")
            return
        }

        XCTAssertEqual(lastMessageFromCurrentUser.text, message2.text)
    }

    func test_lastMessageFromCurrentUser_whenLastMessageIsThreadReply() throws {
        let user: OwnUser = dummyCurrentUser
        let channelId: ChannelId = .unique
        let mainMessageId: String = .unique
        let mainMessage = Message.dummy(authorUserId: dummyUser.id, mentionedUsers: [dummyCurrentUser.toUser])

        let threadMessage = Message.dummy(authorUserId: dummyUser.id, mentionedUsers: [dummyCurrentUser.toUser])

        let channel = dummyPayload(with: channelId, messages: [mainMessage, threadMessage])

        try! database.createCurrentUser(id: user.id)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        guard let channel: ChatChannel = try? database.viewContext.channel(cid: channelId)?.asModel(),
              let lastMessageFromCurrentUser = channel.lastMessageFromCurrentUser else {
            XCTFail("\(#file), \(#function), \(#line) There should be a valid channel")
            return
        }

        XCTAssertEqual(lastMessageFromCurrentUser.text, threadMessage.text)
    }

    func test_DTO_updateFromSamePayload_doNotProduceChanges() throws {
        // Arrange: Store random channel payload to db
        let channelId: ChannelId = .unique
        let payload = ChannelResponse.dummy(cid: channelId)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: payload, query: nil, cache: nil)
        }

        // Act: Save payload again
        let channel = try database.viewContext.saveChannel(payload: payload, query: nil, cache: nil)

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

    func test_channelWithChannelListQuery_isSavedAndLoaded() throws {
        let createdAt = Date.unique
        let query = ChannelListQuery(
            filter: .and([
                .less(.createdAt, than: createdAt),
                .exists(.deletedAt, exists: false)
            ])
        )

        // Create two channels
        let channel1Id: ChannelId = .unique
        let payload1 = dummyPayload(with: channel1Id, createdAt: Date.unique(before: createdAt))

        let channel2Id: ChannelId = .unique
        let payload2 = dummyPayload(with: channel2Id)

        // Save the channels to DB, but only channel 1 is associated with the query
        try! database.writeSynchronously { session in
            try session.saveChannel(payload: payload1, query: query, cache: nil)
            try session.saveChannel(payload: payload2)
        }

        let fetchRequest = ChannelDTO.channelListFetchRequest(query: query, chatClientConfig: .init(apiKeyString: .unique))
        var loadedChannels: [ChannelDTO] {
            try! database.viewContext.fetch(fetchRequest)
        }

        XCTAssertEqual(loadedChannels.count, 1)
        XCTAssertEqual(loadedChannels.first?.cid, channel1Id.rawValue)
    }

    func test_channelWithChannelListQuery_shouldUseLimitAndBatchSize() {
        let query = ChannelListQuery(
            filter: .and([.less(.createdAt, than: .unique), .exists(.deletedAt, exists: false)]),
            pageSize: 25
        )

        let fetchRequest = ChannelDTO.channelListFetchRequest(query: query, chatClientConfig: .init(apiKeyString: .unique))

        XCTAssertEqual(fetchRequest.fetchBatchSize, 25)
        XCTAssertEqual(fetchRequest.fetchLimit, 25)
    }

    func test_channelListQuery_withSorting() {
        // Create two channels queries with different sortings.
        let memberId = UserId.unique
        let filter: Filter<ChannelListFilterScope> = .in(.members, values: [memberId])
        let queryWithDefaultSorting = ChannelListQuery(filter: filter)
        let queryWithUpdatedAtSorting = ChannelListQuery(filter: filter, sort: [.init(key: .updatedAt, isAscending: false)])

        // Create dummy channels payloads with ids: a, b, c, d.
        let payload1 = dummyPayload(with: try! .init(cid: "a:a"), numberOfMessages: 0, members: [.dummy(user: .dummy(userId: memberId))])
        let payload2 = dummyPayload(with: try! .init(cid: "a:b"), numberOfMessages: 0, members: [.dummy(user: .dummy(userId: memberId))])
        let payload3 = dummyPayload(with: try! .init(cid: "a:c"), numberOfMessages: 0, members: [.dummy(user: .dummy(userId: memberId))])
        let payload4 = dummyPayload(with: try! .init(cid: "a:d"), numberOfMessages: 0, members: [.dummy(user: .dummy(userId: memberId))])

        // Get `lastMessageDate` and `created` dates from generated dummy channels and sort the for the default sorting.
        let createdAndLastMessageDates = [payload1, payload2, payload3, payload4]
            .map { $0.channel?.lastMessageAt ?? $0.channel!.createdAt }
            .sorted(by: { $0 > $1 })

        // Get `updatedAt` dates from generated dummy channels and sort the for the updatedAt sorting.
        let updatedAtDates = [payload1, payload2, payload3, payload4]
            .map(\.channel!.updatedAt)
            .sorted(by: { $0 > $1 })

        // Save the channels to DB. It doesn't matter which query we use because the filter for both of them is the same.
        try! database.writeSynchronously { session in
            try session.saveChannel(payload: payload1, query: queryWithDefaultSorting, cache: nil)
            try session.saveChannel(payload: payload2, query: queryWithDefaultSorting, cache: nil)
            try session.saveChannel(payload: payload3, query: queryWithDefaultSorting, cache: nil)
            try session.saveChannel(payload: payload4, query: queryWithDefaultSorting, cache: nil)
        }

        // A fetch request with a default sorting.
        let fetchRequestWithDefaultSorting = ChannelDTO.channelListFetchRequest(query: queryWithDefaultSorting, chatClientConfig: .init(apiKeyString: .unique))
        // A fetch request with a sorting by `updatedAt`.
        let fetchRequestWithUpdatedAtSorting = ChannelDTO.channelListFetchRequest(query: queryWithUpdatedAtSorting, chatClientConfig: .init(apiKeyString: .unique))

        var channelsWithDefaultSorting: [ChannelDTO] { try! database.viewContext.fetch(fetchRequestWithDefaultSorting) }
        var channelsWithUpdatedAtSorting: [ChannelDTO] { try! database.viewContext.fetch(fetchRequestWithUpdatedAtSorting) }

        // Check the default sorting.
        XCTAssertEqual(channelsWithDefaultSorting.count, 4)
        XCTAssertEqual(channelsWithDefaultSorting.map { ($0.lastMessageAt ?? $0.createdAt).bridgeDate }, createdAndLastMessageDates)

        // Check the sorting by `updatedAt`.
        XCTAssertEqual(channelsWithUpdatedAtSorting.count, 4)
        XCTAssertEqual(channelsWithUpdatedAtSorting.map(\.updatedAt.bridgeDate), updatedAtDates)
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
            try session.saveChannel(payload: self.dummyPayload(with: visibleCid1), query: query, cache: nil)

            // Save a channel with `isHidden` = false -> should be visible
            let visible = try session.saveChannel(
                payload: self.dummyPayload(with: visibleCid2, numberOfMessages: 10),
                query: query,
                cache: nil
            )
            visible.isHidden = false

            // Save a channel with `isHidden` = `true` -> should NOT be visible
            let hidden1 = try session.saveChannel(
                payload: self.dummyPayload(with: .unique, numberOfMessages: 10),
                query: query,
                cache: nil
            )
            hidden1.isHidden = true
        }

        let fetchRequest = ChannelDTO.channelListFetchRequest(query: query, chatClientConfig: .init(apiKeyString: .unique))
        let loadedChannels: [ChannelDTO] = try database.viewContext.fetch(fetchRequest)

        XCTAssertEqual(loadedChannels.count, 2)
        XCTAssertTrue(loadedChannels.contains { $0.cid == visibleCid1.rawValue })
        XCTAssertTrue(loadedChannels.contains { $0.cid == visibleCid2.rawValue })
    }

    func test_channelUnreadCount_calculatedCorrectly() throws {
        // GIVEN
        let currentUserPayload: OwnUser = .dummy(userId: .unique, role: .user)

        let currentUserChannelReadPayload = Read(
            lastRead: Date(),
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: currentUserPayload.toUser
        )

        let messageMentioningCurrentUser: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: currentUserChannelReadPayload.lastRead.addingTimeInterval(5),
            mentionedUsers: [currentUserPayload.toUser]
        )

        let channelPayload = ChannelStateResponse.dummy(
            members: [.dummy(user: currentUserPayload.toUser)],
            messages: [messageMentioningCurrentUser],
            reads: [currentUserChannelReadPayload],
            membership: .dummy(user: currentUserPayload.toUser)
        )

        let unreadMessages = 5

        let cid = try ChannelId(cid: channelPayload.channel!.cid)
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUserPayload)
            try session.saveChannel(payload: channelPayload)

            let read = try XCTUnwrap(
                session.loadChannelRead(cid: cid, userId: currentUserPayload.id)
            )
            read.unreadMessageCount = Int32(unreadMessages)
        }

        // WHEN
        let unreadCount = try XCTUnwrap(
            database.viewContext.channel(cid: cid)?.asModel().unreadCount
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
                .init(args: "", description: "", name: "giphy", set: ""),
                .init(args: "", description: "", name: "workout", set: ""),
                .init(args: "", description: "", name: "location", set: "")
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
        let channelPayload: ChannelStateResponse = .dummy()

        let previewMessagePayload: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            text: .unique
        )

        try database.writeSynchronously { session in
            let chanenlDTO = try session.saveChannel(payload: channelPayload)

            chanenlDTO.previewMessage = try session.saveMessage(
                payload: previewMessagePayload,
                channelDTO: chanenlDTO,
                syncOwnReactions: false,
                cache: nil
            )
        }

        // WHEN
        let cid = try ChannelId(cid: channelPayload.channel!.cid)
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)?.asModel()
        )

        // THEN
        let previewMessage = try XCTUnwrap(channel.previewMessage)
        XCTAssertEqual(previewMessage.text, previewMessagePayload.text)
    }

    /// The root cause of this issue can be found on ChatChannel.create(fromDTO:), when creating a block to lazily get
    /// its unread count. To get the data, there is a predicate that looks as follows: `NSPredicate(format: "%@ IN mentionedUsers", currentUser.user)`.
    /// Whenever `currentUser.user` is invalid, this would directly crash as we cannot create a predicate with nil on the left hand side
    /// This test verifies that this code is not executed when `currentUser.user` is invalid
    func test_asModel_shouldNotCrashWhenCurrentUserInvalid() throws {
        // GIVEN
        let channelPayload: ChannelStateResponse = .dummy()
        let userId = UserId.unique

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        // WHEN
        let cid = try ChannelId(cid: channelPayload.channel!.cid)
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)?.asModel()
        )

        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            let managedObjectContext = try XCTUnwrap(currentUser.managedObjectContext)
            managedObjectContext.delete(currentUser.user)
        }

        // THEN
        XCTAssertEqual(channel.unreadCount.messages, 0)
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

        let currentUser: OwnUser = .dummy(userId: .unique, role: .admin)
        let anotherUser: OwnUser = .dummy(userId: .unique, role: .user)

        let cid: ChannelId = .unique

        let message1: Message = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            text: "message1",
            createdAt: .init(),
            cid: cid
        )

        let deletedMessageFromCurrentUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            text: "deletedMessageFromCurrentUser",
            createdAt: message1.createdAt.addingTimeInterval(-1),
            deletedAt: .init(),
            cid: cid
        )

        let deletedMessageFromAnotherUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: "deletedMessageFromAnotherUser",
            createdAt: deletedMessageFromCurrentUser.createdAt.addingTimeInterval(-1),
            deletedAt: .init(),
            cid: cid
        )

        let shadowedMessageFromAnotherUser: Message = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: "shadowedMessageFromAnotherUser",
            createdAt: deletedMessageFromAnotherUser.createdAt.addingTimeInterval(-1),
            cid: cid,
            isShadowed: true
        )

        let message2: Message = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: "message2",
            createdAt: shadowedMessageFromAnotherUser.createdAt.addingTimeInterval(-1),
            cid: cid
        )

        let channelPayload: ChannelStateResponse = .dummy(
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

    // MARK: Max depth

    func test_asModel_onlyFetchesUntilCertainRelationship() throws {
        let originalIsBackgroundMappingEnabled = StreamRuntimeCheck._isBackgroundMappingEnabled
        try test_asModel_onlyFetchesUntilCertainRelationship(isBackgroundMappingEnabled: false)
        try test_asModel_onlyFetchesUntilCertainRelationship(isBackgroundMappingEnabled: true)
        StreamRuntimeCheck._isBackgroundMappingEnabled = originalIsBackgroundMappingEnabled
    }

    private func test_asModel_onlyFetchesUntilCertainRelationship(isBackgroundMappingEnabled: Bool) throws {
        StreamRuntimeCheck._isBackgroundMappingEnabled = isBackgroundMappingEnabled
        let cid = ChannelId.unique

        // GIVEN
        let quoted3MessagePayload: Message = .dummy(
            messageId: .unique,
            cid: cid
        )

        let quoted2MessagePayload: Message = .dummy(
            messageId: .unique,
            quotedMessageId: quoted3MessagePayload.id,
            quotedMessage: quoted3MessagePayload,
            cid: cid
        )

        let message1Payload: Message = .dummy(
            messageId: .unique,
            quotedMessageId: quoted2MessagePayload.id,
            quotedMessage: quoted2MessagePayload,
            cid: cid
        )

        let channelPayload: ChannelStateResponse = .dummy(
            channel: .dummy(cid: cid),
            messages: [
                message1Payload
            ]
        )
        let userId = UserId.unique

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let channel = try XCTUnwrap(database.viewContext.channel(cid: cid)?.asModel())

        // THEN
        let message1 = try XCTUnwrap(channel.latestMessages.first { $0.id == message1Payload.id })
        let quoted2Message = try XCTUnwrap(message1.quotedMessage)
        XCTAssertEqual(quoted2Message.id, quoted2MessagePayload.id)

        let quoted3Message = quoted2Message.quotedMessage
        if isBackgroundMappingEnabled {
            // 3rd level of depth is not mapped
            XCTAssertNil(quoted3Message)
        } else {
            XCTAssertEqual(quoted3Message?.id, quoted3MessagePayload.id)
        }
    }
}

private extension ChannelDTO_Tests {
    func createChannelWithEmptyPaginationCursors() throws -> ChannelDTO {
        let channelPayload = ChannelStateResponse.dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: try ChannelId(cid: channelPayload.channel!.cid))
        )
        return channel
    }

    func channel(with cid: ChannelId) throws -> ChatChannel {
        try XCTUnwrap(database.viewContext.channel(cid: cid)).asModel()
    }
}
