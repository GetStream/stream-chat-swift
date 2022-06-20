//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
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

    var measurePayload: ChannelListPayload {
        let channelsCount = 25 // ChannelDetailPayload
        let userCount = 25 // UserPayload
        let otherWatchersCount = 25 // UserPayload
        let messageCount = 20 // MessagePayload
        let readCountsPerChannel = 0 // ChannelReadPayload
        let messageReactionsCount = 1 // MessageReactionPayload

        return createChannelList(
            channels: channelsCount,
            users: userCount,
            otherWatchers: otherWatchersCount,
            messagesPerChannel: messageCount,
            readCountsPerChannel: readCountsPerChannel,
            messageReactionsPerChannel: messageReactionsCount
        )
    }

    func savePayload(payload: ChannelListPayload, database: DatabaseContainer_Spy) {
        ChannelListPayload_Tests().saveChannelListPayload(payload, database: database, timeout: 40)
    }

    func test_measureBigPayload_recursivelyGetAllIds() {
        let channelList = measurePayload
        var cache: [String: Set<String>] = [:]
        measure {
            cache = channelList.recursivelyGetAllIds()
        }

        XCTAssertEqual(cache.keys.count, 4)
        XCTAssertEqual(cache["\(ChannelDTO.self)"]?.count, 25)
        XCTAssertEqual(cache["\(MessageDTO.self)"]?.count, 500)
        XCTAssertEqual(cache["\(UserDTO.self)"]?.count, 50)
        XCTAssertEqual(cache["\(MessageReactionDTO.self)"]?.count, 1000)
    }

    func test_measureBigPayload_getPayloadToModelIdMappings() {
        let database = DatabaseContainer_Spy()
        let channelList = measurePayload
        savePayload(payload: channelList, database: database)

        var cache: IDToObjectIDCache = [:]
        measure {
            cache = channelList.getPayloadToModelIdMappings(context: database.viewContext)
        }

        XCTAssertEqual(cache.keys.count, 4)
        XCTAssertEqual(cache["\(ChannelDTO.self)"]?.count, 25)
        XCTAssertEqual(cache["\(MessageDTO.self)"]?.count, 500)
        XCTAssertEqual(cache["\(UserDTO.self)"]?.count, 50)
        XCTAssertEqual(cache["\(MessageReactionDTO.self)"]?.count, 1000)
    }

    // Identifiable

    func test_UserListPayload_isIdentifiablePayload() {
        let payload = UserListPayload(users: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(UserListPayload.modelClass)
    }

    func test_MessageListPayload_isIdentifiablePayload() {
        let payload = MessageListPayload(messages: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(MessageListPayload.modelClass)
    }

    func test_MessageReactionsPayload_isIdentifiablePayload() {
        let payload = MessageReactionsPayload(reactions: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(MessageReactionsPayload.modelClass)
    }

    func test_MessagePayloadBoxed_isIdentifiablePayload() {
        let payload = MessagePayload.Boxed(message: .dummy(messageId: "1", authorUserId: ""))
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(MessagePayload.Boxed.modelClass)
    }

    func test_ChannelMemberListPayload_isIdentifiablePayload() {
        let payload = ChannelMemberListPayload(members: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(ChannelMemberListPayload.modelClass)
    }

    func test_ChannelListPayload_isIdentifiablePayload() {
        let payload = ChannelListPayload(channels: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(ChannelListPayload.modelClass)
    }

    func test_ChannelPayload_isIdentifiablePayload() {
        let payload = ChannelPayload.dummy()
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(ChannelPayload.modelClass)
    }

    func test_ChannelDetailPayload_isIdentifiablePayload() {
        let payload = ChannelDetailPayload.dummy(cid: ChannelId(type: .messaging, id: "1"))
        XCTAssertEqual(payload.databaseId, "messaging:1")
        XCTAssertTrue(ChannelDetailPayload.modelClass == ChannelDTO.self)
    }

    func test_UserPayload_isIdentifiablePayload() {
        let payload = UserPayload.dummy(userId: "1")
        XCTAssertEqual(payload.databaseId, "1")
        XCTAssertTrue(UserPayload.modelClass == UserDTO.self)
    }

    func test_MessagePayload_isIdentifiablePayload() {
        let payload = MessagePayload.dummy(messageId: "m1", authorUserId: "u1")
        XCTAssertEqual(payload.databaseId, "m1")
        XCTAssertTrue(MessagePayload.modelClass == MessageDTO.self)
    }

    func test_MessageReactionPayload_isIdentifiablePayload() {
        let payload = MessageReactionPayload.dummy(
            type: MessageReactionType(rawValue: "1"),
            messageId: "2",
            user: UserPayload.dummy(userId: "3")
        )
        XCTAssertEqual(payload.databaseId, "3/2/1")
        XCTAssertTrue(MessageReactionPayload.modelClass == MessageReactionDTO.self)
    }

    func test_MemberPayload_isIdentifiablePayload() {
        let payload = MemberPayload.dummy(user: .dummy(userId: "u2"))
        XCTAssertNil(payload.databaseId)
        XCTAssertTrue(MemberPayload.modelClass == MemberDTO.self)
    }

    func test_ChannelReadPayload_isIdentifiablePayload() {
        let payload = ChannelReadPayload(user: .dummy(userId: "u3"), lastReadAt: Date(), unreadMessagesCount: 2)
        XCTAssertNil(payload.databaseId)
        XCTAssertTrue(ChannelReadPayload.modelClass == ChannelReadDTO.self)
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

        let userIds = try XCTUnwrap(cache[UserDTO.className])
        let channelDetailIds = try XCTUnwrap(cache[ChannelDTO.className])

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

        let userIds = try XCTUnwrap(cache[UserDTO.className])
        let channelDetailIds = try XCTUnwrap(cache[ChannelDTO.className])

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

        let reactionIds = try XCTUnwrap(cache[MessageReactionDTO.className])
        let userIds = try XCTUnwrap(cache[UserDTO.className])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(reactionIds, ["u3/m2/r1"])
        XCTAssertEqual(userIds, ["u3"])
    }

    func test_bigChannelListPayload_recursivelyIdentifiablePayload() throws {
        let channelsCount = 4 // ChannelDetailPayload
        let userCount = 4 // UserPayload
        let otherWatchersCount = 4 // UserPayload
        let messageCount = 4 // MessagePayload
        let messageReactionsCount = 1 // MessageReactionPayload

        let channelList = createChannelList(
            channels: channelsCount,
            users: userCount,
            otherWatchers: otherWatchersCount,
            messagesPerChannel: messageCount,
            readCountsPerChannel: 0,
            messageReactionsPerChannel: messageReactionsCount
        )

        let cache = channelList.recursivelyGetAllIds()

        let channelIds = try XCTUnwrap(cache[ChannelDTO.className])
        let messageIds = try XCTUnwrap(cache[MessageDTO.className])
        let userIds = try XCTUnwrap(cache[UserDTO.className])
        let reactionIds = try XCTUnwrap(cache[MessageReactionDTO.className])

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
        XCTAssertEqual(reactionIds.count, messageCount * channelsCount * 2)
        let expectedReactionIds = (0..<channelsCount).flatMap { channelId in
            (0..<messageCount).flatMap { messageId in
                [
                    MessageReactionDTO.createId(
                        userId: "user-\(0)",
                        messageId: "message-c:\(channelId)-\(messageId)",
                        type: "like"
                    ),
                    MessageReactionDTO.createId(
                        userId: "user-\(0)",
                        messageId: "message-c:\(channelId)-\(messageId)",
                        type: "love"
                    )
                ]
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
                let messageAuthor = users[channelIndex]
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
