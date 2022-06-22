//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListPayload_Tests: XCTestCase {
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

    func saveChannelListPayload(_ payload: ChannelListPayload, database: DatabaseContainer_Spy, timeout: TimeInterval = 10) {
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

    func test_hugeChannelListQuery_save_uncached() throws {
        let decodedPayload = createHugeChannelList()
        measure {
            let databaseContainer = DatabaseContainer_Spy()
            saveChannelListPayload(decodedPayload, database: databaseContainer)
        }
    }

    func test_hugeChannelListQuery_save_cached() throws {
        let decodedPayload = createHugeChannelList()
        let databaseContainer = DatabaseContainer_Spy()

        saveChannelListPayload(decodedPayload, database: databaseContainer)

        measure {
            saveChannelListPayload(decodedPayload, database: databaseContainer)
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
            let channelDetail = ChannelDetailPayload(
                cid: cid,
                name: .unique,
                imageURL: .unique(),
                extraData: [:],
                typeRawValue: cid.type.rawValue,
                lastMessageAt: lastMessageDate,
                createdAt: channelCreatedDate,
                deletedAt: nil,
                updatedAt: .unique(after: channelCreatedDate),
                truncatedAt: nil,
                createdBy: channelOwner,
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
                            description: "test command",
                            set: "test",
                            args: "test"
                        )
                    ],
                    createdAt: channelCreatedDate,
                    updatedAt: .unique
                ),
                isFrozen: true,
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
                team: .unique,
                cooldownDuration: .random(in: 0...120)
            )
            
            let messages = (0..<messageCount).map { messageIndex -> MessagePayload in
                let messageId = "\(channelIndex)-\(messageIndex)"
                let messageCreatedDate = Date.unique(after: channelCreatedDate)
                let messageAuthor = channelUsers.randomElement()!
                return MessagePayload(
                    id: messageId,
                    type: .regular,
                    user: messageAuthor,
                    createdAt: messageCreatedDate,
                    updatedAt: .unique,
                    deletedAt: nil,
                    text: .unique,
                    command: .unique,
                    args: .unique,
                    parentId: nil,
                    showReplyInChannel: .random(),
                    quotedMessageId: nil,
                    quotedMessage: nil,
                    mentionedUsers: messageIndex % 2 == 0 ? [channelUsers.randomElement()!] : [],
                    threadParticipants: [],
                    replyCount: .random(in: 0...10),
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
                    reactionScores: [:],
                    reactionCounts: [:],
                    isSilent: false,
                    isShadowed: false,
                    attachments: messageIndex % 2 == 0 ? [.dummy()] : [],
                    channel: channelDetail,
                    pinned: false,
                    pinnedBy: nil,
                    pinnedAt: nil,
                    pinExpires: nil
                )
            }
            
            return ChannelPayload(
                channel: channelDetail,
                watcherCount: 0,
                watchers: [],
                members: channelDetail.members!,
                membership: MemberPayload.dummy(
                    user: channelOwner,
                    createdAt: channelOwner.createdAt,
                    updatedAt: channelOwner.updatedAt,
                    role: .admin,
                    isMemberBanned: false
                ),
                messages: messages,
                pinnedMessages: [],
                channelReads: (0..<channelReadCount).map { i in
                    ChannelReadPayload(
                        user: channelUsers[i],
                        lastReadAt: .unique(after: channelCreatedDate),
                        unreadMessagesCount: (0..<10).randomElement()!
                    )
                },
                isHidden: false
            )
        }
        
        return ChannelListPayload(channels: channels)
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
        XCTAssertEqual(payload.isHidden, true)
        XCTAssertEqual(payload.watchers?.first?.id, "cilvia")
        
        XCTAssertEqual(payload.messages.count, 25)
        let firstMessage = payload.messages.first(where: { $0.id == "broken-waterfall-5-7aede36b-b89f-4f45-baff-c40c7c1875d9" })!
        
        XCTAssertEqual(firstMessage.type, MessageType.regular)
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

        XCTAssertEqual(payload.pinnedMessages.map(\.id), ["broken-waterfall-5-7aede36b-b89f-4f45-baff-c40c7c1875d9"])
        
        let channel = payload.channel
        XCTAssertEqual(channel.cid, try! ChannelId(cid: "messaging:general"))
        XCTAssertEqual(channel.createdAt, "2019-05-10T14:03:49.505006Z".toDate())
        XCTAssertNotNil(channel.createdBy)
        XCTAssertEqual(channel.typeRawValue, "messaging")
        XCTAssertEqual(channel.isFrozen, true)
        XCTAssertEqual(channel.memberCount, 4)
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
        
        let config = channel.config
        XCTAssertEqual(config.reactionsEnabled, true)
        XCTAssertEqual(config.typingEventsEnabled, true)
        XCTAssertEqual(config.readEventsEnabled, true)
        XCTAssertEqual(config.connectEventsEnabled, true)
        XCTAssertEqual(config.uploadsEnabled, true)
        XCTAssertEqual(config.repliesEnabled, true)
        XCTAssertEqual(config.quotesEnabled, true)
        XCTAssertEqual(config.searchEnabled, true)
        XCTAssertEqual(config.mutesEnabled, true)
        XCTAssertEqual(config.urlEnrichmentEnabled, true)
        XCTAssertEqual(config.messageRetention, "infinite")
        XCTAssertEqual(config.maxMessageLength, 5000)
        XCTAssertEqual(
            config.commands,
            [.init(name: "giphy", description: "Post a random gif to the channel", set: "fun_set", args: "[text]")]
        )
        XCTAssertEqual(config.createdAt, "2019-03-21T15:49:15.40182Z".toDate())
        XCTAssertEqual(config.updatedAt, "2020-03-17T18:54:09.460881Z".toDate())

        XCTAssertEqual(payload.membership?.user.id, "broken-waterfall-5")
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
}
