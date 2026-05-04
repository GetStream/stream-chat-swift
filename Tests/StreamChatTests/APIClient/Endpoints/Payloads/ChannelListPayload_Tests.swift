//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListPayload_Tests: XCTestCase {
    private var database: DatabaseContainer_Spy!
    
    override func setUpWithError() throws {
        // Clean up any db files left behind
        FileManager.removeAllTemporaryFiles()
    }
    
    override func tearDownWithError() throws {
        database = nil
    }
    
    func test_channelQueryJSON_isSerialized_withDefaultExtraData() throws {
        // GIVEN
        let url = XCTestCase.mockData(fromJSONFile: "ChannelsQuery")

        // WHEN
        let payload = try JSONDecoder.default.decode(ChannelListPayload.self, from: url)

        // THEN
        XCTAssertEqual(payload.channels.count, 20)
    }

    func test_decode_bigChannelListPayload() {
        // 3MB JSON Channel List from Watercooler
        let url = XCTestCase.mockData(fromJSONFile: "BigChannelListPayload")

        measure {
            do {
                _ = try JSONDecoder.default.decode(ChannelListPayload.self, from: url)
            } catch {
                XCTFail("Failed to parse JSON: \(error)")
            }
        }
    }

    func test_decode_shouldThrowWhenChannelHasMissingRequiredProperties() throws {
        /// OpenAPI types are strict: any missing required property fails the whole decode.
        let url = XCTestCase.mockData(fromJSONFile: "PartiallyFailingChannelListPayload")
        XCTAssertThrowsError(try JSONDecoder.default.decode(ChannelListPayload.self, from: url))
    }

    func test_decode_shouldThrowWhenOneChannelCompletelyFailsParsing() throws {
        /// OpenAPI types are strict: any channel with missing required properties fails the whole decode.
        let url = XCTestCase.mockData(fromJSONFile: "FailingChannelListPayload")
        XCTAssertThrowsError(try JSONDecoder.default.decode(ChannelListPayload.self, from: url))
    }

    func saveChannelListPayload(_ payload: ChannelListPayload, database: DatabaseContainer_Spy, timeout: TimeInterval = 20) {
        let writeCompleted = expectation(description: "DB write complete")
        database.write({ session in
            session.saveChannelList(payload: payload, query: .init(filter: .containMembers(userIds: [.unique])))
        }, completion: { error in
            if let error = error {
                XCTFail("DB write error: \(error)")
            }
            writeCompleted.fulfill()
        })
        wait(for: [writeCompleted], timeout: timeout)
    }

    func test_hugeChannelListQuery_save_DB_empty() throws {
        let decodedPayload = createHugeChannelList()
        let timeout: TimeInterval = 180
        database = DatabaseContainer_Spy(kind: .onDisk(databaseFileURL: .newTemporaryFileURL()))
        measure {
            saveChannelListPayload(decodedPayload, database: database, timeout: timeout)
        }
    }

    func test_hugeChannelListQuery_save_DB_filled() throws {
        let decodedPayload = createHugeChannelList()
        database = DatabaseContainer_Spy(kind: .onDisk(databaseFileURL: .newTemporaryFileURL()))
        let timeout: TimeInterval = 180

        saveChannelListPayload(decodedPayload, database: database, timeout: timeout)

        measure {
            saveChannelListPayload(decodedPayload, database: database, timeout: timeout)
        }
    }

    func createHugeChannelList() -> ChannelListPayload {
        let userCount = 600
        let channelCount = 20
        let messageCount = 25
        let channelReadCount = 20

        let users = (0..<max(userCount, 30)).map { userIndex in UserPayload.dummy(userId: "\(userIndex)") }
        let channels = (0..<channelCount).map { channelIndex -> ChannelPayload in
            let channelUsers = users.shuffled().prefix(30)

            let channelCreatedDate = Date.unique
            let lastMessageDate = Date.unique(after: channelCreatedDate)

            let cid = ChannelId(type: .messaging, id: "\(channelIndex)")
            let channelOwner = channelUsers.randomElement()!
            let channelDetail = ChannelDetailPayload.dummy(
                cid: cid,
                name: .unique,
                imageURL: .unique(),
                extraData: [:],
                lastMessageAt: lastMessageDate,
                createdAt: channelCreatedDate,
                updatedAt: .unique(after: channelCreatedDate),
                createdBy: channelOwner,
                filterTags: ["football"],
                ownCapabilities: ["join-channel", "delete-channel"],
                isFrozen: true,
                isBlocked: false,
                isDisabled: false,
                isHidden: false,
                members: channelUsers.map {
                    MemberPayload.dummy(
                        user: $0,
                        createdAt: $0.createdAt,
                        updatedAt: $0.updatedAt,
                        role: .member,
                        isMemberBanned: false
                    )
                },
                memberCount: 100,
                messageCount: 100,
                team: .unique,
                cooldownDuration: .random(in: 0...120)
            )

            let messages = (0..<messageCount).map { messageIndex -> MessagePayload in
                let messageId = "\(channelIndex)-\(messageIndex)"
                let messageCreatedDate = Date.unique(after: channelCreatedDate)
                let messageAuthor = channelUsers.randomElement()!
                return MessagePayload.dummy(
                    messageId: messageId,
                    showReplyInChannel: .random(),
                    threadParticipants: [],
                    attachments: messageIndex % 2 == 0 ? [.dummy()] : [],
                    authorUserId: messageAuthor.id,
                    text: .unique,
                    extraData: [:],
                    latestReactions: messageIndex % 2 == 0 ? (0..<3).map { _ in
                        MessageReactionPayload(
                            type: "like",
                            score: 1,
                            messageId: messageId,
                            createdAt: .unique(after: messageCreatedDate),
                            updatedAt: .unique(after: messageCreatedDate),
                            user: channelUsers.randomElement()!,
                            extraData: [:]
                        )
                    } : [],
                    ownReactions: messageIndex % 2 == 0 ? (0..<3).map { _ in
                        MessageReactionPayload(
                            type: "like",
                            score: 1,
                            messageId: messageId,
                            createdAt: .unique(after: messageCreatedDate),
                            updatedAt: .unique(after: messageCreatedDate),
                            user: messageAuthor,
                            extraData: [:]
                        )
                    } : [],
                    createdAt: messageCreatedDate,
                    updatedAt: .unique,
                    channel: channelDetail,
                    reactionScores: [:],
                    reactionCounts: [:],
                    mentionedUsers: messageIndex % 2 == 0 ? [channelUsers.randomElement()!] : []
                )
            }

            return ChannelPayload.dummy(
                channel: channelDetail,
                watcherCount: 0,
                watchers: [],
                members: channelDetail.members ?? [],
                membership: MemberPayload.dummy(
                    user: channelOwner,
                    createdAt: channelOwner.createdAt,
                    updatedAt: channelOwner.updatedAt,
                    role: .admin,
                    isMemberBanned: false
                ),
                messages: messages,
                pendingMessages: [],
                pinnedMessages: [],
                channelReads: (0..<channelReadCount).map { i in
                    ChannelReadPayload(
                        user: channelUsers[i],
                        lastReadAt: .unique(after: channelCreatedDate),
                        lastReadMessageId: .unique,
                        unreadMessagesCount: (0..<10).randomElement()!,
                        lastDeliveredAt: nil,
                        lastDeliveredMessageId: nil
                    )
                },
                isHidden: false,
                draft: nil,
                activeLiveLocations: [],
                pushPreference: nil
            )
        }

        return ChannelListPayload(channels: channels, duration: "")
    }
}

final class ChannelPayload_Tests: XCTestCase {
    func test_channelJSON_isSerialized_withDefaultExtraData() throws {
        // GIVEN
        let url = XCTestCase.mockData(fromJSONFile: "Channel")

        // WHEN
        let payload = try JSONDecoder.default.decode(ChannelPayload.self, from: url)

        // THEN
        XCTAssertEqual(payload.watcherCount, 7)
        XCTAssertEqual(payload.watchers?.count, 3)
        XCTAssertEqual(payload.members.count, 4)
        XCTAssertEqual(payload.hidden, true)
        XCTAssertEqual(payload.watchers?.first?.id, "cilvia")

        XCTAssertEqual(payload.messages.count, 25)
        let firstMessage = payload.messages.first(where: { $0.id == "broken-waterfall-5-7aede36b-b89f-4f45-baff-c40c7c1875d9" })!

        XCTAssertEqual(firstMessage.type, MessageType.regular.rawValue)
        XCTAssertEqual(firstMessage.user.id, "broken-waterfall-5")
        XCTAssertEqual(firstMessage.createdAt, "2020-06-09T08:10:40.800912Z".toDate())
        XCTAssertEqual(firstMessage.updatedAt, "2020-06-09T08:10:40.800912Z".toDate())
        XCTAssertNil(firstMessage.deletedAt)
        XCTAssertEqual(firstMessage.text, "sadfadf")
        XCTAssertNil(firstMessage.command)
        XCTAssertNil(firstMessage.args)
        XCTAssertNil(firstMessage.parentId)
        XCTAssertFalse(firstMessage.showReplyInChannel)
        XCTAssert(firstMessage.mentionedUsers.isEmpty)
        XCTAssert(firstMessage.reactionScores.isEmpty)
        XCTAssertEqual(firstMessage.replyCount, 0)
        XCTAssertFalse(firstMessage.isSilent)

        XCTAssertEqual(payload.pendingMessages?.count ?? 0, 1)
        let pendingMessage = try XCTUnwrap(payload.pendingMessages?.first)
        XCTAssertEqual(pendingMessage.message?.text, "My pending message")

        XCTAssertEqual(payload.pinnedMessages.map(\.id), ["broken-waterfall-5-7aede36b-b89f-4f45-baff-c40c7c1875d9"])

        let channel = try XCTUnwrap(payload.channel)
        XCTAssertEqual(channel.cid, "messaging:general")
        XCTAssertEqual(channel.createdAt, "2019-05-10T14:03:49.505006Z".toDate())
        XCTAssertNotNil(channel.createdBy)
        XCTAssertEqual(channel.typeRawValue, "messaging")
        XCTAssertEqual(channel.isDisabled, true)
        XCTAssertEqual(channel.isFrozen, true)
        XCTAssertEqual(channel.memberCount, 4)
        XCTAssertEqual(channel.messageCount, 5)
        XCTAssertEqual(channel.updatedAt, "2019-05-10T14:03:49.505006Z".toDate())
        XCTAssertEqual(channel.cooldownDuration, 10)
        XCTAssertEqual(channel.team, "GREEN")

        XCTAssertEqual(channel.name, "The water cooler")
        XCTAssertEqual(
            channel.imageURL?.absoluteString,
            "https://images.unsplash.com/photo-1512138664757-360e0aad5132?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2851&q=80"
        )

        let firstChannelRead = payload.channelReads.first!
        XCTAssertEqual(firstChannelRead.lastReadAt, "2020-06-10T07:43:11.812841984Z".toDate())
        XCTAssertEqual(firstChannelRead.unreadMessagesCount, 0)
        XCTAssertEqual(firstChannelRead.user.id, "broken-waterfall-5")

        let config = try XCTUnwrap(channel.config?.asChannelConfig)
        XCTAssertEqual(config.reactionsEnabled, true)
        XCTAssertEqual(config.typingEventsEnabled, true)
        XCTAssertEqual(config.readEventsEnabled, true)
        XCTAssertEqual(config.deliveryEventsEnabled, false)
        XCTAssertEqual(config.connectEventsEnabled, true)
        XCTAssertEqual(config.uploadsEnabled, true)
        XCTAssertEqual(config.repliesEnabled, true)
        XCTAssertEqual(config.quotesEnabled, true)
        XCTAssertEqual(config.searchEnabled, true)
        XCTAssertEqual(config.mutesEnabled, true)
        XCTAssertEqual(config.urlEnrichmentEnabled, true)
        XCTAssertEqual(config.maxMessageLength, 5000)
        XCTAssertEqual(config.skipLastMsgAtUpdateForSystemMsg, true)
        XCTAssertEqual(config.sharedLocationsEnabled, true)
        XCTAssertEqual(
            config.commands,
            [
                .init(name: "giphy", description: "Post a random gif to the channel", set: "fun_set", args: "[text]"),
                .init(name: "flag", description: "Flag a user", set: "moderation_set", args: "[@username]")
            ]
        )
        XCTAssertEqual(config.createdAt, "2019-03-21T15:49:15.40182Z".toDate())
        XCTAssertEqual(config.updatedAt, "2020-03-17T18:54:09.460881Z".toDate())

        XCTAssertEqual(payload.membership?.user?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.channel?.filterTags, ["football"])
        XCTAssertEqual(payload.channel?.ownCapabilities?.count, 27)
        XCTAssertEqual(payload.activeLiveLocations?.count, 1)
        XCTAssertNotNil(payload.pushPreferences)
    }

    func test_newestMessage_whenMessagesAreSortedDesc() throws {
        // GIVEN
        let earlierMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init()
        )

        let laterMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: earlierMessage.createdAt.addingTimeInterval(10)
        )

        // WHEN
        let payload: ChannelPayload = .dummy(
            messages: [
                laterMessage,
                earlierMessage
            ]
        )

        // THEN
        XCTAssertEqual(payload.newestMessage?.id, laterMessage.id)
    }

    func test_newestMessage_whenMessagesAreSortedAsc() throws {
        // GIVEN
        let earlierMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init()
        )

        let laterMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: earlierMessage.createdAt.addingTimeInterval(10)
        )

        // WHEN
        let payload: ChannelPayload = .dummy(
            messages: [
                earlierMessage,
                laterMessage
            ]
        )

        // THEN
        XCTAssertEqual(payload.newestMessage?.id, laterMessage.id)
    }
    
    // MARK: - ChannelPayload.asModel() Tests
    
    func test_channelPayload_asModel_convertsAllPropertiesCorrectly() {
        let currentUserId = "current-user-id"
        let cid = ChannelId(type: .messaging, id: "test-channel")
        
        let createdByPayload = UserPayload.dummy(userId: "creator-user-id", name: "Channel Creator")
        let memberPayload = MemberPayload.dummy(user: UserPayload.dummy(userId: "member-user-id"), role: .member)
        let watcherPayload = UserPayload.dummy(userId: "watcher-user-id", name: "Channel Watcher")
        let messagePayload = MessagePayload.dummy(messageId: "message-id", authorUserId: "author-id")
        let pinnedMessagePayload = MessagePayload.dummy(messageId: "pinned-message-id", authorUserId: "pinned-author-id")
        let pendingMessagePayload = MessagePayload.dummy(messageId: "pending-message-id", authorUserId: "pending-author-id")
        
        let channelReadPayload = ChannelReadPayload(
            user: UserPayload.dummy(userId: "reader-user-id", name: "Reader User"),
            lastReadAt: Date(timeIntervalSince1970: 1_609_459_400),
            lastReadMessageId: "last-read-message-id",
            unreadMessagesCount: 5,
            lastDeliveredAt: nil,
            lastDeliveredMessageId: nil
        )
        
        let membershipPayload = MemberPayload.dummy(user: UserPayload.dummy(userId: currentUserId), role: .admin)

        let channel = ChannelDetailPayload.dummy(
            cid: cid,
            name: "Test Channel",
            imageURL: URL(string: "https://example.com/channel.png"),
            extraData: ["custom_field": .string("custom_value")],
            lastMessageAt: Date(timeIntervalSince1970: 1_609_459_500),
            createdAt: Date(timeIntervalSince1970: 1_609_459_200),
            deletedAt: Date(timeIntervalSince1970: 1_609_459_600),
            updatedAt: Date(timeIntervalSince1970: 1_609_459_300),
            truncatedAt: Date(timeIntervalSince1970: 1_609_459_250),
            createdBy: createdByPayload,
            filterTags: ["football"],
            ownCapabilities: ["send-message", "upload-file"],
            isFrozen: true,
            isBlocked: true,
            isDisabled: true,
            isHidden: true,
            members: [memberPayload],
            memberCount: 10,
            messageCount: 10,
            team: "team-id",
            cooldownDuration: 30
        )

        let typingUsers = Set([ChatUser.mock(id: "typing-user-id", name: "Typing User")])
        let unreadCount = ChannelUnreadCount(messages: 3, mentions: 1)

        let payload = ChannelPayload.dummy(
            channel: channel,
            watcherCount: 5,
            watchers: [watcherPayload],
            members: [memberPayload],
            membership: membershipPayload,
            messages: [messagePayload],
            pendingMessages: [pendingMessagePayload],
            pinnedMessages: [pinnedMessagePayload],
            channelReads: [channelReadPayload],
            isHidden: true,
            draft: nil,
            activeLiveLocations: [],
            pushPreference: nil
        )
        
        let chatChannel = payload.asModel(
            currentUserId: currentUserId,
            currentlyTypingUsers: typingUsers,
            unreadCount: unreadCount
        )
        
        XCTAssertEqual(chatChannel.cid, cid)
        XCTAssertEqual(chatChannel.name, "Test Channel")
        XCTAssertEqual(chatChannel.imageURL, URL(string: "https://example.com/channel.png"))
        XCTAssertEqual(chatChannel.lastMessageAt, Date(timeIntervalSince1970: 1_609_459_500))
        XCTAssertEqual(chatChannel.createdAt, Date(timeIntervalSince1970: 1_609_459_200))
        XCTAssertEqual(chatChannel.updatedAt, Date(timeIntervalSince1970: 1_609_459_300))
        XCTAssertEqual(chatChannel.deletedAt, Date(timeIntervalSince1970: 1_609_459_600))
        XCTAssertEqual(chatChannel.truncatedAt, Date(timeIntervalSince1970: 1_609_459_250))
        XCTAssertEqual(chatChannel.isHidden, true)
        XCTAssertEqual(chatChannel.createdBy?.id, "creator-user-id")
        XCTAssertNotNil(chatChannel.config)
        XCTAssertEqual(chatChannel.filterTags, ["football"])
        XCTAssertTrue(chatChannel.ownCapabilities.contains(.sendMessage))
        XCTAssertTrue(chatChannel.ownCapabilities.contains(.uploadFile))
        XCTAssertEqual(chatChannel.isFrozen, true)
        XCTAssertEqual(chatChannel.isDisabled, true)
        XCTAssertEqual(chatChannel.isBlocked, true)
        XCTAssertEqual(chatChannel.lastActiveMembers.count, 1)
        XCTAssertEqual(chatChannel.lastActiveMembers.first?.id, "member-user-id")
        XCTAssertEqual(chatChannel.membership?.id, currentUserId)
        XCTAssertEqual(chatChannel.currentlyTypingUsers, typingUsers)
        XCTAssertEqual(chatChannel.lastActiveWatchers.count, 1)
        XCTAssertEqual(chatChannel.lastActiveWatchers.first?.id, "watcher-user-id")
        XCTAssertEqual(chatChannel.team, "team-id")
        XCTAssertEqual(chatChannel.unreadCount, unreadCount)
        XCTAssertEqual(chatChannel.watcherCount, 5)
        XCTAssertEqual(chatChannel.memberCount, 10)
        XCTAssertEqual(chatChannel.messageCount, 10)
        XCTAssertEqual(chatChannel.reads.count, 1)
        XCTAssertEqual(chatChannel.reads.first?.user.id, "reader-user-id")
        XCTAssertEqual(chatChannel.cooldownDuration, 30)
        XCTAssertEqual(chatChannel.extraData, ["custom_field": .string("custom_value")])
        XCTAssertEqual(chatChannel.latestMessages.count, 1)
        XCTAssertEqual(chatChannel.latestMessages.first?.id, "message-id")
        XCTAssertEqual(chatChannel.pinnedMessages.count, 1)
        XCTAssertEqual(chatChannel.pinnedMessages.first?.id, "pinned-message-id")
        XCTAssertEqual(chatChannel.pendingMessages.count, 1)
        XCTAssertEqual(chatChannel.pendingMessages.first?.id, "pending-message-id")
        XCTAssertNil(chatChannel.muteDetails)
        XCTAssertEqual(chatChannel.latestMessages.first?.id, "message-id")
        XCTAssertTrue(chatChannel.activeLiveLocations.isEmpty)
    }
    
    func test_channelPayload_asModel_withMinimalData_handlesCorrectly() {
        let currentUserId = "current-user-id"
        let cid = ChannelId(type: .messaging, id: "minimal-channel")
        
        let channel = ChannelDetailPayload.dummy(
            cid: cid,
            name: "Minimal Channel",
            imageURL: nil,
            extraData: [:],
            lastMessageAt: Date(timeIntervalSince1970: 1_609_459_200),
            createdAt: Date(timeIntervalSince1970: 1_609_459_200),
            updatedAt: Date(timeIntervalSince1970: 1_609_459_200),
            createdBy: nil,
            members: [],
            memberCount: 0,
            cooldownDuration: 0
        )

        let payload = ChannelPayload.dummy(
            channel: channel,
            watcherCount: nil,
            watchers: [],
            members: [],
            membership: nil,
            messages: [],
            pendingMessages: [],
            pinnedMessages: [],
            channelReads: [],
            isHidden: nil,
            draft: nil,
            activeLiveLocations: [],
            pushPreference: nil
        )
        
        let chatChannel = payload.asModel(
            currentUserId: currentUserId,
            currentlyTypingUsers: nil,
            unreadCount: nil
        )
        
        XCTAssertEqual(chatChannel.cid, cid)
        XCTAssertEqual(chatChannel.name, "Minimal Channel")
        XCTAssertNil(chatChannel.imageURL)
        XCTAssertEqual(chatChannel.lastMessageAt, Date(timeIntervalSince1970: 1_609_459_200))
        XCTAssertEqual(chatChannel.createdAt, Date(timeIntervalSince1970: 1_609_459_200))
        XCTAssertEqual(chatChannel.updatedAt, Date(timeIntervalSince1970: 1_609_459_200))
        XCTAssertNil(chatChannel.deletedAt)
        XCTAssertNil(chatChannel.truncatedAt)
        XCTAssertEqual(chatChannel.isHidden, false)
        XCTAssertNil(chatChannel.createdBy)
        XCTAssertNotNil(chatChannel.config)
        XCTAssertTrue(chatChannel.filterTags.isEmpty)
        XCTAssertTrue(chatChannel.ownCapabilities.isEmpty)
        XCTAssertEqual(chatChannel.isFrozen, false)
        XCTAssertEqual(chatChannel.isDisabled, false)
        XCTAssertEqual(chatChannel.isBlocked, false)
        XCTAssertTrue(chatChannel.lastActiveMembers.isEmpty)
        XCTAssertNil(chatChannel.membership)
        XCTAssertTrue(chatChannel.currentlyTypingUsers.isEmpty)
        XCTAssertTrue(chatChannel.lastActiveWatchers.isEmpty)
        XCTAssertNil(chatChannel.team)
        XCTAssertEqual(chatChannel.unreadCount, .noUnread)
        XCTAssertEqual(chatChannel.watcherCount, 0)
        XCTAssertEqual(chatChannel.memberCount, 0)
        XCTAssertEqual(chatChannel.messageCount, nil)
        XCTAssertTrue(chatChannel.reads.isEmpty)
        XCTAssertEqual(chatChannel.cooldownDuration, 0)
        XCTAssertEqual(chatChannel.extraData, [:])
        XCTAssertTrue(chatChannel.latestMessages.isEmpty)
        XCTAssertTrue(chatChannel.pinnedMessages.isEmpty)
        XCTAssertTrue(chatChannel.pendingMessages.isEmpty)
        XCTAssertNil(chatChannel.muteDetails)
        XCTAssertTrue(chatChannel.latestMessages.isEmpty)
        XCTAssertNil(chatChannel.lastMessageFromCurrentUser)
        XCTAssertNil(chatChannel.draftMessage)
        XCTAssertTrue(chatChannel.activeLiveLocations.isEmpty)
    }
}
