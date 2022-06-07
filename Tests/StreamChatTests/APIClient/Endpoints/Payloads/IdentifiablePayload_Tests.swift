//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import SwiftUI
import XCTest

final class IdentifiablePayload_Tests: XCTestCase {
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

    // Fetch
    func test_mesureBigPayload_getPayloadToModelIdMappings() {
        let channelsCount = 14 // ChannelDetailPayload
        let userCount = 14 // UserPayload
        let otherWatchersCount = 14 // UserPayload
        let messageCount = 14 // MessagePayload
        let messageReactionsCount = 13 // MessageReactionPayload

        let channelList = createChannelList(
            channels: channelsCount,
            users: userCount,
            otherWatchers: otherWatchersCount,
            messagesPerChannel: messageCount,
            readCountsPerChannel: 0,
            messageReactionsPerChannel: messageReactionsCount
        )
        measure {
            _ = channelList.getPayloadToModelIdMappings(context: database.viewContext)
        }
    }

    // Identifiable

    func test_ChannelListPayload_isIdentifiablePayload() {
        let payload = ChannelListPayload(channels: [])
        XCTAssertNil(payload.databaseId)
    }

    func test_ChannelPayload_isIdentifiablePayload() {
        let payload = ChannelPayload.dummy()
        XCTAssertNil(payload.databaseId)
    }

    func test_ChannelDetailPayload_isIdentifiablePayload() {
        let payload = ChannelDetailPayload.dummy(cid: ChannelId(type: .messaging, id: "1"))
        XCTAssertEqual(ChannelDetailPayload.keyPath, "cid")
        XCTAssertEqual(payload.databaseId, "messaging:1")
    }

    func test_UserPayload_isIdentifiablePayload() {
        let payload = UserPayload.dummy(userId: "1")
        XCTAssertEqual(UserPayload.keyPath, "id")
        XCTAssertEqual(payload.databaseId, "1")
    }

    func test_MessagePayload_isIdentifiablePayload() {
        let payload = MessagePayload.dummy(messageId: "m1", authorUserId: "u1")
        XCTAssertEqual(MessagePayload.keyPath, "id")
        XCTAssertEqual(payload.databaseId, "m1")
    }

    func test_MessageReactionPayload_isIdentifiablePayload() {
        let payload = MessageReactionPayload.dummy(
            type: MessageReactionType(rawValue: "1"),
            messageId: "2",
            user: UserPayload.dummy(userId: "3")
        )
        XCTAssertEqual(MessageReactionPayload.keyPath, "id")
        XCTAssertEqual(payload.databaseId, "3/2/1")
    }

    func test_MemberPayload_isIdentifiablePayload() {
        let payload = MemberPayload.dummy(user: .dummy(userId: "u2"))
        XCTAssertEqual(MemberPayload.keyPath, "id")
        XCTAssertNil(payload.databaseId)
    }

    func test_ChannelReadPayload_isIdentifiablePayload() {
        let payload = ChannelReadPayload(user: .dummy(userId: "u3"), lastReadAt: Date(), unreadMessagesCount: 2)
        XCTAssertNil(ChannelReadPayload.keyPath)
        XCTAssertNil(payload.databaseId)
    }

    // Recursion

    func test_ChannelListPayload_isIdentifiablePayload_recursively() throws {
        let watchers = (0..<4).map {
            UserPayload.dummy(userId: "\($0)")
        }
        let cid = ChannelId.unique
        let channelDetailPayload = ChannelDetailPayload.dummy(cid: cid, createdBy: watchers[0])
        let channelPayload = ChannelPayload.dummy(channel: channelDetailPayload, watchers: watchers)
        let payload = ChannelListPayload(channels: [channelPayload])

        let cache = payload.recursivelyGetAllIds()

        let userIds = try XCTUnwrap(cache["\(UserPayload.self)"])
        let channelDetailIds = try XCTUnwrap(cache["\(ChannelDetailPayload.self)"])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(userIds, ["0", "1", "2", "3"])
        XCTAssertEqual(channelDetailIds, [cid.rawValue])
    }

    func test_ChannelPayload_isIdentifiablePayload_recursively() throws {
        let watchers = (0..<4).map {
            UserPayload.dummy(userId: "\($0)")
        }
        let cid = ChannelId.unique
        let channelDetailPayload = ChannelDetailPayload.dummy(cid: cid, createdBy: watchers[0])
        let payload = ChannelPayload.dummy(channel: channelDetailPayload, watchers: watchers)

        let cache = payload.recursivelyGetAllIds()

        let userIds = try XCTUnwrap(cache["\(UserPayload.self)"])
        let channelDetailIds = try XCTUnwrap(cache["\(ChannelDetailPayload.self)"])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(userIds, ["0", "1", "2", "3"])
        XCTAssertEqual(channelDetailIds, [cid.rawValue])
    }

    func test_MessageReactionPayload_isIdentifiablePayload_recursively() throws {
        let payload = MessageReactionPayload.dummy(
            type: MessageReactionType(rawValue: "r1"),
            messageId: "m2",
            user: UserPayload.dummy(userId: "u3")
        )

        let cache = payload.recursivelyGetAllIds()

        let reactionIds = try XCTUnwrap(cache["\(MessageReactionPayload.self)"])
        let userIds = try XCTUnwrap(cache["\(UserPayload.self)"])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(reactionIds, ["u3/m2/r1"])
        XCTAssertEqual(userIds, ["u3"])
    }

    func test_bigChannelListPayload_recursivelyIdentifiablePayload() throws {
        let channelsCount = 4 // ChannelDetailPayload
        let userCount = 4 // UserPayload
        let otherWatchersCount = 4 // UserPayload
        let messageCount = 4 // MessagePayload
        let messageReactionsCount = 3 // MessageReactionPayload

        let channelList = createChannelList(
            channels: channelsCount,
            users: userCount,
            otherWatchers: otherWatchersCount,
            messagesPerChannel: messageCount,
            readCountsPerChannel: 0,
            messageReactionsPerChannel: messageReactionsCount
        )

        let cache = channelList.recursivelyGetAllIds()

        let channelIds = try XCTUnwrap(cache["\(ChannelDetailPayload.self)"])
        let messageIds = try XCTUnwrap(cache["\(MessagePayload.self)"])
        let userIds = try XCTUnwrap(cache["\(UserPayload.self)"])
        let reactionIds = try XCTUnwrap(cache["\(MessageReactionPayload.self)"])

        XCTAssertEqual(cache.keys.count, 4)
        // Channels
        XCTAssertEqual(channelIds, ["messaging:channel-0", "messaging:channel-1", "messaging:channel-2", "messaging:channel-3"])
        // Messages
        XCTAssertEqual(messageIds.count, messageCount * channelsCount)
        let expectedMessageIds = (0..<channelsCount).flatMap { channelId in
            (0..<messageCount).map {
                "message-c:\(channelId)-\($0)"
            }
        }
        XCTAssertEqual(messageIds, Set(expectedMessageIds))
        // Users
        XCTAssertEqual(userIds, ["user-0", "user-1", "user-2", "user-3", "watcher-4", "watcher-5", "watcher-6", "watcher-7"])
        // Reactions
        XCTAssertEqual(reactionIds.count, messageCount * messageReactionsCount * channelsCount * 2)
        let expectedReactionIds = (0..<channelsCount).flatMap { channelId in
            (0..<messageCount).flatMap { messageId in
                (0..<messageReactionsCount).flatMap {
                    [
                        MessageReactionDTO.createId(
                            userId: "user-\($0)",
                            messageId: "message-c:\(channelId)-\(messageId)",
                            type: "like"
                        ),
                        MessageReactionDTO.createId(
                            userId: "user-\($0)",
                            messageId: "message-c:\(channelId)-\(messageId)",
                            type: "love"
                        )
                    ]
                }
            }
        }
        XCTAssertEqual(reactionIds, Set(expectedReactionIds))
    }

    func createChannelList(
        channels: Int,
        users: Int,
        otherWatchers: Int,
        messagesPerChannel: Int,
        readCountsPerChannel: Int,
        messageReactionsPerChannel: Int
    ) -> ChannelListPayload {
        let channelsCount = channels
        let userCount = users
        let otherWatchersCount = otherWatchers
        let messageCount = messagesPerChannel
        let channelReadCount = readCountsPerChannel
        let messageReactionsCount = messageReactionsPerChannel
        let channels: [ChannelPayload] = (0..<channelsCount).map { channelIndex in
            let users = (0..<userCount).map { UserPayload.dummy(userId: "user-\($0)") }
            let watchers = (userCount..<userCount + otherWatchersCount).map { UserPayload.dummy(userId: "watcher-\($0)") }
            let owner = users[channelIndex]
            let cid = ChannelId(type: .messaging, id: "channel-\(channelIndex)")
            let channelDetail = ChannelDetailPayload(
                cid: cid,
                name: .unique,
                imageURL: .unique(),
                extraData: [:],
                typeRawValue: cid.type.rawValue,
                lastMessageAt: Date(),
                createdAt: Date(),
                deletedAt: nil,
                updatedAt: .unique(after: Date()),
                truncatedAt: nil,
                createdBy: owner,
                config: .mock(),
                isFrozen: true,
                isHidden: false,
                members: users.map { MemberPayload.dummy(user: $0) },
                memberCount: users.count,
                team: .unique,
                cooldownDuration: 20
            )

            func anotherUser(differentThan: Int) -> UserPayload {
                if differentThan + 1 >= users.count {
                    return users[0]
                } else {
                    return users[differentThan + 1]
                }
            }

            let messages = (0..<messageCount).map { messageIndex -> MessagePayload in
                let messageId = "message-c:\(channelIndex)-\(messageIndex)"
                let messageCreatedDate = Date.unique(after: Date())
                let messageAuthor = users[messageIndex]
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
                    mentionedUsers: [anotherUser(differentThan: messageIndex)],
                    threadParticipants: [],
                    replyCount: .random(in: 0...10),
                    extraData: [:],
                    latestReactions: (0..<messageReactionsCount).map {
                        MessageReactionPayload(
                            type: "like",
                            score: 1,
                            messageId: messageId,
                            createdAt: .unique(after: messageCreatedDate),
                            updatedAt: .unique(after: messageCreatedDate),
                            user: users[$0],
                            extraData: [:]
                        )
                    },
                    ownReactions: (0..<messageReactionsCount).map {
                        MessageReactionPayload(
                            type: "love",
                            score: 1,
                            messageId: messageId,
                            createdAt: .unique(after: messageCreatedDate),
                            updatedAt: .unique(after: messageCreatedDate),
                            user: users[$0],
                            extraData: [:]
                        )
                    },
                    reactionScores: [:],
                    reactionCounts: [:],
                    isSilent: false,
                    isShadowed: false,
                    attachments: [],
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
                watchers: watchers,
                members: channelDetail.members!,
                membership: MemberPayload.dummy(
                    user: owner,
                    createdAt: owner.createdAt,
                    updatedAt: owner.updatedAt,
                    role: .admin,
                    isMemberBanned: false
                ),
                messages: messages,
                pinnedMessages: [],
                channelReads: (0..<channelReadCount).map { i in
                    ChannelReadPayload(
                        user: users[i],
                        lastReadAt: .unique(after: channelDetail.createdAt),
                        unreadMessagesCount: (0..<10).randomElement()!
                    )
                },
                isHidden: false
            )
        }

        return ChannelListPayload(channels: channels)
    }
}
