//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    var measurePayload: QueryChannelsResponse {
        let channelsCount = 25 // ChannelResponse
        let userCount = 25 // UserResponse
        let otherWatchersCount = 25 // UserResponse
        let messageCount = 20 // MessageResponse
        let readCountsPerChannel = 0 // ReadStateResponse
        let messageReactionsCount = 1 // ReactionResponse

        return createChannelList(
            channels: channelsCount,
            users: userCount,
            otherWatchers: otherWatchersCount,
            messagesPerChannel: messageCount,
            readCountsPerChannel: readCountsPerChannel,
            messageReactionsPerChannel: messageReactionsCount
        )
    }

    func savePayload(payload: QueryChannelsResponse, database: DatabaseContainer_Spy) {
        QueryChannelsResponse_Tests().saveQueryChannelsResponse(payload, database: database, timeout: 40)
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
    
    func test_concurrentPerform_getPayloadToModelIdMappings() {
        let database = DatabaseContainer_Spy()
        let channelList = createChannelList(
            channels: 5,
            users: 5,
            otherWatchers: 2,
            messagesPerChannel: 10,
            readCountsPerChannel: 2,
            messageReactionsPerChannel: 2
        )
        savePayload(payload: channelList, database: database)

        let contexts = [database.writableContext, database.backgroundReadOnlyContext, database.stateLayerContext]
        let iterations = 2000
        var caches: [PreWarmedCache] = (0..<iterations).map { _ in [:] }
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            autoreleasepool {
                let context = contexts[index % contexts.count]
                caches[index] = channelList.getPayloadToModelIdMappings(context: context)
            }
        }
        
        for cache in caches {
            XCTAssertEqual(cache.keys.count, 4)
            XCTAssertEqual(cache["\(ChannelDTO.self)"]?.count, 5)
            XCTAssertEqual(cache["\(MessageDTO.self)"]?.count, 50)
            XCTAssertEqual(cache["\(UserDTO.self)"]?.count, 7)
            XCTAssertEqual(cache["\(MessageReactionDTO.self)"]?.count, 200)
        }
    }

    // Identifiable

    func test_UserListPayload_isIdentifiablePayload() {
        let payload = QueryUsersResponse.dummy(users: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(QueryUsersResponse.modelClass)
    }

    func test_MessageListPayload_isIdentifiablePayload() {
        let payload = MessageListPayload(messages: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(MessageListPayload.modelClass)
    }

    func test_MessageReactionsPayload_isIdentifiablePayload() {
        let payload = GetReactionsResponse(duration: "", reactions: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(GetReactionsResponse.modelClass)
    }

    func test_MembersResponse_isIdentifiablePayload() {
        let payload = MembersResponse.dummy(members: [])
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(MembersResponse.modelClass)
    }

    func test_QueryChannelsResponse_isIdentifiablePayload() {
        let payload = QueryChannelsResponse(channels: [], duration: "")
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(QueryChannelsResponse.modelClass)
    }

    func test_ChannelStateResponseFields_isIdentifiablePayload() {
        let payload = ChannelStateResponseFields.dummy()
        XCTAssertNil(payload.databaseId)
        XCTAssertNil(ChannelStateResponseFields.modelClass)
    }

    func test_ChannelResponse_isIdentifiablePayload() {
        let payload = ChannelResponse.dummy(cid: ChannelId(type: .messaging, id: "1"))
        XCTAssertEqual(payload.databaseId, "messaging:1")
        XCTAssertTrue(ChannelResponse.modelClass == ChannelDTO.self)
    }

    func test_UserResponse_isIdentifiablePayload() {
        let payload = UserResponse.dummy(userId: "1")
        XCTAssertEqual(payload.databaseId, "1")
        XCTAssertTrue(UserResponse.modelClass == UserDTO.self)
    }

    func test_MessageResponse_isIdentifiablePayload() {
        let payload = MessageResponse.dummy(messageId: "m1", authorUserId: "u1")
        XCTAssertEqual(payload.databaseId, "m1")
        XCTAssertTrue(MessageResponse.modelClass == MessageDTO.self)
    }

    func test_MessageReactionPayload_isIdentifiablePayload() {
        let payload = ReactionResponse.dummy(
            type: MessageReactionType(rawValue: "1"),
            messageId: "2",
            user: UserResponse.dummy(userId: "3")
        )
        XCTAssertEqual(payload.databaseId, "3/2/1")
        XCTAssertTrue(ReactionResponse.modelClass == MessageReactionDTO.self)
    }

    func test_ChannelMemberResponse_isIdentifiablePayload() {
        let payload = ChannelMemberResponse.dummy(user: UserResponse.dummy(userId: "u2"))
        XCTAssertNil(payload.databaseId)
        XCTAssertTrue(ChannelMemberResponse.modelClass == MemberDTO.self)
    }

    func test_ReadStateResponse_isIdentifiablePayload() {
        let payload = ReadStateResponse.dummy(
            lastDeliveredAt: nil,
            lastDeliveredMessageId: nil,
            lastRead: Date(),
            lastReadMessageId: .unique,
            unreadMessages: 2,
            user: UserResponse.dummy(userId: "u3")
        )
        XCTAssertNil(payload.databaseId)
        XCTAssertTrue(ReadStateResponse.modelClass == ChannelReadDTO.self)
    }

    // Recursion

    func test_QueryChannelsResponse_isIdentifiablePayload_recursively() throws {
        let watchers = (0..<4).map {
            UserResponse.dummy(userId: "\($0)")
        }
        let cid = ChannelId.unique
        let channelDetailPayload = ChannelResponse.dummy(cid: cid, createdBy: watchers[0])
        let channelPayload = ChannelStateResponseFields.dummy(channel: channelDetailPayload, watchers: watchers)
        let payload = QueryChannelsResponse(channels: [channelPayload], duration: "")

        let cache = payload.recursivelyGetAllIds()

        let userIds = try XCTUnwrap(cache[UserDTO.className])
        let channelDetailIds = try XCTUnwrap(cache[ChannelDTO.className])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(userIds, ["0", "1", "2", "3"])
        XCTAssertEqual(channelDetailIds, [cid.rawValue])
    }

    func test_ChannelStateResponseFields_isIdentifiablePayload_recursively() throws {
        let watchers = (0..<4).map {
            UserResponse.dummy(userId: "\($0)")
        }
        let cid = ChannelId.unique
        let channelDetailPayload = ChannelResponse.dummy(cid: cid, createdBy: watchers[0])
        let payload = ChannelStateResponseFields.dummy(channel: channelDetailPayload, watchers: watchers)

        let cache = payload.recursivelyGetAllIds()

        let userIds = try XCTUnwrap(cache[UserDTO.className])
        let channelDetailIds = try XCTUnwrap(cache[ChannelDTO.className])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(userIds, ["0", "1", "2", "3"])
        XCTAssertEqual(channelDetailIds, [cid.rawValue])
    }

    func test_MessageReactionPayload_isIdentifiablePayload_recursively() throws {
        let payload = ReactionResponse.dummy(
            type: MessageReactionType(rawValue: "r1"),
            messageId: "m2",
            user: UserResponse.dummy(userId: "u3")
        )

        let cache = payload.recursivelyGetAllIds()

        let reactionIds = try XCTUnwrap(cache[MessageReactionDTO.className])
        let userIds = try XCTUnwrap(cache[UserDTO.className])

        XCTAssertEqual(cache.keys.count, 2)
        XCTAssertEqual(reactionIds, ["u3/m2/r1"])
        XCTAssertEqual(userIds, ["u3"])
    }

    func test_ThreadStateResponse_whenParentMessageIsMissing_doesNotCacheSyntheticParentMessage() throws {
        let parentMessageId = MessageId.unique
        let payload = ThreadStateResponse.dummy(
            parentMessageId: parentMessageId
        )

        let cache = payload.recursivelyGetAllIds()

        XCTAssertEqual(cache[ThreadDTO.className], [parentMessageId])
        XCTAssertFalse(cache[MessageDTO.className]?.contains(parentMessageId) ?? false)
    }

    func test_ThreadStateResponse_whenParentMessageExists_cachesParentMessage() throws {
        let parentMessageId = MessageId.unique
        let payload = ThreadStateResponse.dummy(
            parentMessage: .dummy(messageId: parentMessageId),
            parentMessageId: parentMessageId
        )

        let cache = payload.recursivelyGetAllIds()

        XCTAssertEqual(cache[ThreadDTO.className], [parentMessageId])
        XCTAssertTrue(cache[MessageDTO.className]?.contains(parentMessageId) ?? false)
    }

    func test_bigQueryChannelsResponse_recursivelyIdentifiablePayload() throws {
        let channelsCount = 4 // ChannelResponse
        let userCount = 4 // UserResponse
        let otherWatchersCount = 4 // UserResponse
        let messageCount = 4 // MessageResponse
        let messageReactionsCount = 1 // ReactionResponse

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
    ) -> QueryChannelsResponse {
        let channelsCount = channels
        let userCount = users
        let otherWatchersCount = otherWatchers
        let messageCount = messagesPerChannel
        let channelReadCount = readCountsPerChannel
        let messageReactionsCount = messageReactionsPerChannel
        let channels: [ChannelStateResponseFields] = (0..<channelsCount).map { channelIndex in
            let users = (0..<userCount).map { UserResponse.dummy(userId: "user-\($0)") }
            let watchers = (userCount..<userCount + otherWatchersCount).map { UserResponse.dummy(userId: "watcher-\($0)") }
            let owner = users[channelIndex]
            let cid = ChannelId(type: .messaging, id: "channel-\(channelIndex)")
            let channelDetail = ChannelResponse.dummy(
                cid: cid,
                name: .unique,
                imageURL: .unique(),
                extraData: [:],
                lastMessageAt: Date(),
                createdAt: Date(),
                updatedAt: .unique(after: Date()),
                createdBy: owner,
                ownCapabilities: [],
                isFrozen: true,
                isBlocked: false,
                isDisabled: false,
                isHidden: false,
                members: users.map { ChannelMemberResponse.dummy(user: $0) },
                memberCount: users.count,
                messageCount: messageCount,
                team: .unique,
                cooldownDuration: 20
            )

            func anotherUser(differentThan: Int) -> UserResponse {
                if differentThan + 1 >= users.count {
                    return users[0]
                } else {
                    return users[differentThan + 1]
                }
            }

            let messages = (0..<messageCount).map { messageIndex -> MessageResponse in
                let messageId = "message-c:\(channelIndex)-\(messageIndex)"
                let messageCreatedDate = Date.unique(after: Date())
                let messageAuthor = users[channelIndex]
                return MessageResponse.dummy(
                    messageId: messageId,
                    showReplyInChannel: .random(),
                    threadParticipants: [],
                    attachments: [],
                    authorUserId: messageAuthor.id,
                    text: .unique,
                    extraData: [:],
                    latestReactions: (0..<messageReactionsCount).map {
                        ReactionResponse.dummy(
                            type: "like",
                            score: 1,
                            messageId: messageId,
                            createdAt: .unique(after: messageCreatedDate),
                            updatedAt: .unique(after: messageCreatedDate),
                            user: users[$0]
                        )
                    },
                    ownReactions: (0..<messageReactionsCount).map {
                        ReactionResponse.dummy(
                            type: "love",
                            score: 1,
                            messageId: messageId,
                            createdAt: .unique(after: messageCreatedDate),
                            updatedAt: .unique(after: messageCreatedDate),
                            user: users[$0]
                        )
                    },
                    createdAt: messageCreatedDate,
                    updatedAt: .unique,
                    channel: channelDetail,
                    reactionScores: [:],
                    reactionCounts: [:],
                    mentionedUsers: [anotherUser(differentThan: messageIndex)]
                )
            }

            return ChannelStateResponseFields.dummy(
                channel: channelDetail,
                watcherCount: 0,
                watchers: watchers,
                members: channelDetail.members ?? [],
                membership: ChannelMemberResponse.dummy(
                    user: owner,
                    createdAt: owner.createdAt,
                    updatedAt: owner.updatedAt,
                    role: .admin,
                    isMemberBanned: false
                ),
                messages: messages,
                pendingMessages: [],
                pinnedMessages: [],
                channelReads: (0..<channelReadCount).map { i in
                    ReadStateResponse.dummy(
                        lastDeliveredAt: nil,
                        lastDeliveredMessageId: nil,
                        lastRead: .unique(after: channelDetail.createdAt),
                        lastReadMessageId: .unique,
                        unreadMessages: (0..<10).randomElement()!,
                        user: users[i]
                    )
                },
                isHidden: false,
                draft: nil,
                activeLiveLocations: [],
                pushPreference: nil
            )
        }

        return QueryChannelsResponse(channels: channels, duration: "")
    }
}
