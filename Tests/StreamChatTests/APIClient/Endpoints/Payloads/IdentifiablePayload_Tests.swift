//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    var measurePayload: ChannelsResponse {
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

    func savePayload(payload: ChannelsResponse, database: DatabaseContainer_Spy) {
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

        var cache: PreWarmedCache = [:]
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
        let payload = QueryUsersResponse(duration: "", users: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(QueryUsersResponse.modelClass)
    }

    func test_MessageListPayload_isIdentifiablePayload() {
        let payload = GetRepliesResponse(duration: "", messages: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(GetRepliesResponse.modelClass)
    }

    func test_MessageReactionsPayload_isIdentifiablePayload() {
        let payload = GetReactionsResponse(duration: "", reactions: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(GetReactionsResponse.modelClass)
    }

    func test_MessagePayloadBoxed_isIdentifiablePayload() {
        // TODO: check this.
//        let payload = MessagePayload.Boxed(message: .dummy(messageId: "1", authorUserId: ""))
//        XCTAssertNil(payload.databaseId)
//        XCTAssertNil(MessagePayload.Boxed.modelClass)
    }

    func test_ChannelMemberListPayload_isIdentifiablePayload() {
        let payload = MembersResponse(duration: "", members: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(MembersResponse.modelClass)
    }

    func test_ChannelListPayload_isIdentifiablePayload() {
        let payload = ChannelsResponse(channels: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(ChannelsResponse.modelClass)
    }

    func test_ChannelPayload_isIdentifiablePayload() {
        let payload = ChannelStateResponse.dummy().toResponseFields
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(ChannelStateResponseFields.modelClass)
    }

    func test_ChannelDetailPayload_isIdentifiablePayload() {
        let payload = ChannelResponse.dummy(cid: ChannelId(type: .messaging, id: "1"))
        XCTAssertEqual(payload.databaseId, "messaging:1")
        XCTAssertTrue(ChannelResponse.modelClass == ChannelDTO.self)
    }

    func test_UserPayload_isIdentifiablePayload() {
        let payload = UserObject.dummy(userId: "1")
        XCTAssertEqual(payload.databaseId, "1")
        XCTAssertTrue(UserObject.modelClass == UserDTO.self)
    }

    func test_MessagePayload_isIdentifiablePayload() {
        let payload = Message.dummy(messageId: "m1", authorUserId: "u1")
        XCTAssertEqual(payload.databaseId, "m1")
        XCTAssertTrue(Message.modelClass == MessageDTO.self)
    }

    func test_MessageReactionPayload_isIdentifiablePayload() {
        let payload = Reaction.dummy(
            type: MessageReactionType(rawValue: "1"),
            messageId: "2",
            user: UserObject.dummy(userId: "3")
        )
        XCTAssertEqual(payload.databaseId, "3/2/1")
        XCTAssertTrue(Reaction.modelClass == MessageReactionDTO.self)
    }

    func test_MemberPayload_isIdentifiablePayload() {
        let payload = ChannelMember.dummy(user: .dummy(userId: "u2"))
        XCTAssertNil(payload.databaseId)
        XCTAssertTrue(ChannelMember.modelClass == MemberDTO.self)
    }

    func test_ChannelReadPayload_isIdentifiablePayload() {
        let payload = Read(
            lastRead: Date(),
            unreadMessages: 2,
            lastReadMessageId: .unique,
            user: .dummy(userId: "u3")
        )
        XCTAssertNil(payload.databaseId)
        XCTAssertTrue(Read.modelClass == ChannelReadDTO.self)
    }

    // Recursion

    func test_ChannelListPayload_isIdentifiablePayload_recursively() throws {
        let watchers = (0..<4).map {
            UserObject.dummy(userId: "\($0)")
        }
        let cid = ChannelId.unique
        let channelDetailPayload = ChannelResponse.dummy(cid: cid, createdBy: watchers[0])
        let channelPayload = ChannelStateResponse.dummy(
            cid: cid,
            channel: channelDetailPayload,
            reads: [],
            membership: nil,
            watchers: watchers
        )
        
        let payload = ChannelsResponse(channels: [channelPayload])

        let cache = payload.recursivelyGetAllIds()

        let userIds = try XCTUnwrap(cache[UserDTO.className])
        let channelDetailIds = try XCTUnwrap(cache[ChannelDTO.className])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(userIds, ["0", "1", "2", "3"])
        XCTAssertEqual(channelDetailIds, [cid.rawValue])
    }

    func test_ChannelPayload_isIdentifiablePayload_recursively() throws {
        let watchers = (0..<4).map {
            UserObject.dummy(userId: "\($0)")
        }
        let cid = ChannelId.unique
        let channelDetailPayload = ChannelResponse.dummy(cid: cid, createdBy: watchers[0])
        let payload = ChannelStateResponse.dummy(channel: channelDetailPayload, watchers: watchers).toResponseFields

        let cache = payload.recursivelyGetAllIds()

        let userIds = try XCTUnwrap(cache[UserDTO.className])
        let channelDetailIds = try XCTUnwrap(cache[ChannelDTO.className])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(userIds, ["0", "1", "2", "3"])
        XCTAssertEqual(channelDetailIds, [cid.rawValue])
    }

    func test_MessageReactionPayload_isIdentifiablePayload_recursively() throws {
        let payload = Reaction.dummy(
            type: MessageReactionType(rawValue: "r1"),
            messageId: "m2",
            user: UserObject.dummy(userId: "u3")
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
    ) -> ChannelsResponse {
        let channelsCount = channels
        let userCount = users
        let otherWatchersCount = otherWatchers
        let messageCount = messagesPerChannel
        let channelReadCount = readCountsPerChannel
        let messageReactionsCount = messageReactionsPerChannel
        let channels: [ChannelStateResponse] = (0..<channelsCount).map { channelIndex in
            let users = (0..<userCount).map { UserObject.dummy(userId: "user-\($0)") }
            let watchers = (userCount..<userCount + otherWatchersCount).map { UserObject.dummy(userId: "watcher-\($0)") }
            let owner = users[channelIndex]
            let cid = ChannelId(type: .messaging, id: "channel-\(channelIndex)")
            let channelDetail = ChannelResponse.dummy(
                cid: cid,
                createdBy: users.randomElement()!,
                members: users.map { user in
                    ChannelMember(
                        banned: false,
                        channelRole: "user",
                        createdAt: Date(),
                        shadowBanned: false,
                        updatedAt: .unique,
                        user: user
                    )
                }
            )

            func anotherUser(differentThan: Int) -> UserObject {
                if differentThan + 1 >= users.count {
                    return users[0]
                } else {
                    return users[differentThan + 1]
                }
            }

            let messages = (0..<messageCount).map { messageIndex -> Message in
                let messageId = "message-c:\(channelIndex)-\(messageIndex)"
                let messageCreatedDate = Date.unique(after: Date())
                let messageAuthor = users[channelIndex]
                return Message.dummy(
                    messageId: messageId,
                    threadParticipants: [],
                    authorUserId: messageAuthor.id,
                    latestReactions: (0..<messageReactionsCount).map { _ in
                        Reaction(
                            createdAt: .unique,
                            messageId: messageId,
                            score: 1,
                            type: "like",
                            updatedAt: .unique,
                            custom: [:],
                            userId: users[0].id,
                            user: users[0]
                        )
                    },
                    ownReactions: (0..<messageReactionsCount).map { _ in
                        Reaction(
                            createdAt: .unique,
                            messageId: messageId,
                            score: 1,
                            type: "love",
                            updatedAt: .unique,
                            custom: [:],
                            userId: users[0].id,
                            user: users[0]
                        )
                    },
                    createdAt: messageCreatedDate,
                    cid: cid,
                    mentionedUsers: []
                )
            }

            return ChannelStateResponse.dummy(
                cid: cid,
                channel: channelDetail,
                members: channelDetail.members!.compactMap { $0 },
                messages: messages,
                reads: (0..<channelReadCount).map { i in
                    Read(
                        lastRead: .unique(after: channelDetail.createdAt),
                        unreadMessages: (0..<10).randomElement()!,
                        lastReadMessageId: .unique,
                        user: users[i]
                    )
                },
                membership: ChannelMember.dummy(
                    user: owner,
                    createdAt: owner.createdAt!,
                    updatedAt: owner.updatedAt!,
                    role: .admin,
                    isMemberBanned: false
                ),
                watchers: watchers
            )
        }

        return ChannelsResponse(channels: channels)
    }
}
