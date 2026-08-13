//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessagePayload_Tests: XCTestCase {
    let messageJSON = XCTestCase.mockData(fromJSONFile: "Message")
    let messageJSONWithCorruptedAttachments = XCTestCase.mockData(fromJSONFile: "MessageWithBrokenAttachments")
    let messageCustomData: [String: RawJSON] = ["secret_note": .string("Anakin is Vader!")]

    func test_messagePayload_decodesEnhancedMentions() throws {
        let json = """
        {
            "id": "msg-1",
            "type": "regular",
            "user": {
                "id": "user-1",
                "role": "user",
                "online": false,
                "created_at": "2020-07-16T15:39:03.010717Z",
                "updated_at": "2020-08-17T13:15:39.895109Z"
            },
            "created_at": "2020-07-16T15:39:03.010717Z",
            "updated_at": "2020-08-17T13:15:39.895109Z",
            "text": "Hey @here, @backendsupport, and @admin",
            "html": "Hey @here, @backendsupport, and @admin",
            "reply_count": 0,
            "reaction_scores": {},
            "silent": false,
            "attachments": [],
            "latest_reactions": [],
            "own_reactions": [],
            "mentioned_users": [],
            "mentioned_here": true,
            "mentioned_channel": true,
            "mentioned_groups": [{"id": "backendsupport", "name": "Backend Support", "created_at": "2020-07-16T15:39:03.010717Z", "updated_at": "2020-08-17T13:15:39.895109Z"}],
            "mentioned_roles": ["admin"]
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(MessagePayload.self, from: json)

        XCTAssertEqual(payload.mentionedHere, true)
        XCTAssertEqual(payload.mentionedChannel, true)
        XCTAssertEqual(payload.mentionedGroups?.map(\.id), ["backendsupport"])
        XCTAssertEqual(payload.mentionedGroups?.map(\.name), ["Backend Support"])
        XCTAssertEqual(payload.mentionedRoles, ["admin"])
    }

    func test_messagePayload_enhancedMentionsAreNilWhenMissing() throws {
        let json = """
        {
            "id": "msg-1",
            "type": "regular",
            "user": {
                "id": "user-1",
                "role": "user",
                "online": false,
                "created_at": "2020-07-16T15:39:03.010717Z",
                "updated_at": "2020-08-17T13:15:39.895109Z"
            },
            "created_at": "2020-07-16T15:39:03.010717Z",
            "updated_at": "2020-08-17T13:15:39.895109Z",
            "text": "Hello",
            "html": "Hello",
            "reply_count": 0,
            "reaction_scores": {},
            "silent": false,
            "attachments": [],
            "latest_reactions": [],
            "own_reactions": [],
            "mentioned_users": []
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(MessagePayload.self, from: json)

        XCTAssertNil(payload.mentionedHere)
        XCTAssertNil(payload.mentionedChannel)
        XCTAssertNil(payload.mentionedGroups)
        XCTAssertNil(payload.mentionedRoles)

        // The defaults are applied when the payload is converted to a model
        let message = payload.asModel(cid: .unique, currentUserId: nil, channelReads: [])
        XCTAssertFalse(message.mentionedHere)
        XCTAssertFalse(message.mentionedChannel)
        XCTAssertTrue(message.mentionedGroups.isEmpty)
        XCTAssertEqual(message.mentionedRoles, [])
    }

    func test_messagePayload_isSerialized_withDefaultExtraData() throws {
        let box = try JSONDecoder.stream.decode(MessagePayload.Boxed.self, from: messageJSON)
        let payload = box.message

        XCTAssertEqual(payload.id, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.type, "regular")
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.messageTextUpdatedAt, "2023-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
        XCTAssertEqual(payload.parentId, "3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.showInChannel, true)
        XCTAssertEqual(payload.mentionedUsers.map(\.id), [])
        XCTAssertEqual(payload.threadParticipants?.map(\.id), ["josh", "vader"])
        XCTAssertEqual(payload.replyCount, 0)
        XCTAssertEqual(payload.custom, messageCustomData)
        XCTAssertEqual(payload.latestReactions.count, 1)
        XCTAssertEqual(payload.ownReactions.count, 1)
        XCTAssertEqual(payload.reactionScores, ["love": 1])
        XCTAssertEqual(payload.reactionCounts, ["love": 1])
        let reactionGroups = try XCTUnwrap(payload.reactionGroups)
        XCTAssertEqual(reactionGroups.keys.sorted(), ["love"])
        let reactionGroup = try XCTUnwrap(reactionGroups["love"] ?? nil)
        XCTAssertEqual(reactionGroup.sumScores, 1)
        XCTAssertEqual(reactionGroup.count, 1)
        XCTAssertEqual(reactionGroup.firstReactionAt, "2024-04-17T13:14:53.643826Z".toDate())
        XCTAssertEqual(reactionGroup.lastReactionAt, "2024-04-17T13:15:53.643826Z".toDate())
        XCTAssertEqual(payload.silent, true)
        XCTAssertEqual(payload.shadowed, true)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:channel-ex7-63")
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.translations, [.italian: "si sono qui", .dutch: "ja ik ben hier"])
        XCTAssertEqual(payload.originalLanguage, "it")
        XCTAssertEqual(payload.moderation?.action, "bounce")
        XCTAssertEqual(payload.moderation?.originalText, "The message original text")
        XCTAssertEqual(payload.moderation?.textHarms, ["sexual_harrassment", "self_harm"])
        XCTAssertEqual(payload.moderation?.imageHarms, ["nudity"])
        XCTAssertEqual(payload.moderation?.blocklistsMatched, ["profanity_2021_01"])
        XCTAssertEqual(payload.moderation?.semanticFilterMatched, "bad_phrases")
        XCTAssertEqual(payload.moderation?.platformCircumvented, false)
        XCTAssertEqual(payload.deletedForMe, true)
        XCTAssertEqual(payload.member?.channelRole, "moderator")
        XCTAssertEqual(payload.member?.notificationsMuted, false)
        XCTAssertEqual(payload.member?.custom, [String: RawJSON]())
    }

    func test_memberInfoPayload_decodesV1InlineCustomKeys() throws {
        let json = """
        {
            "channel_role": "channel_member",
            "notifications_muted": false,
            "badge": { "tier": "gold" }
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(MemberInfoPayload.self, from: json)

        XCTAssertEqual(payload.channelRole, "channel_member")
        XCTAssertEqual(payload.notificationsMuted, false)
        XCTAssertEqual(payload.custom, ["badge": .dictionary(["tier": .string("gold")])])
    }

    func test_memberInfoPayload_knownFieldsAreNotInExtraData() throws {
        let json = """
        {
            "channel_role": "moderator",
            "notifications_muted": true
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(MemberInfoPayload.self, from: json)

        XCTAssertEqual(payload.channelRole, "moderator")
        XCTAssertEqual(payload.notificationsMuted, true)
        XCTAssertEqual(payload.custom, [String: RawJSON]())
    }

    func test_memberInfoPayload_requiredFieldsThrowWhenMissing() throws {
        let fields: [(key: String, json: String)] = [
            ("channel_role", #"{"notifications_muted":false}"#),
            ("notifications_muted", #"{"channel_role":"channel_member"}"#)
        ]

        for field in fields {
            XCTAssertThrowsError(
                try JSONDecoder.stream.decode(MemberInfoPayload.self, from: Data(field.json.utf8)),
                "Expected decoding to fail when \(field.key) is missing"
            )
        }
    }

    func test_messagePayload_requiredFieldsThrowWhenMissing() throws {
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: messageJSON) as? [String: Any])
        let message = try XCTUnwrap(root["message"] as? [String: Any])

        for field in ["reaction_scores", "silent"] {
            var candidateRoot = root
            var candidateMessage = message
            candidateMessage.removeValue(forKey: field)
            candidateRoot["message"] = candidateMessage
            let data = try JSONSerialization.data(withJSONObject: candidateRoot)

            XCTAssertThrowsError(
                try JSONDecoder.stream.decode(MessagePayload.Boxed.self, from: data),
                "Expected decoding to fail when \(field) is missing"
            )
        }
    }

    func test_messagePayload_isSerialized_withDefaultExtraData_withBrokenAttachmentPayload() throws {
        let box = try JSONDecoder.default.decode(MessagePayload.Boxed.self, from: messageJSONWithCorruptedAttachments)
        let payload = box.message

        var messageCustomData = self.messageCustomData
        messageCustomData["tau"] = .double(6.28)

        XCTAssertEqual(payload.id, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.type, "regular")
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
        XCTAssertEqual(payload.parentId, "3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.showInChannel, true)
        XCTAssertEqual(payload.mentionedUsers.map(\.id), [])
        XCTAssertEqual(payload.threadParticipants?.map(\.id), ["josh"])
        XCTAssertEqual(payload.replyCount, 0)
        XCTAssertEqual(payload.custom, messageCustomData)
        XCTAssertEqual(payload.latestReactions.count, 1)
        XCTAssertEqual(payload.ownReactions.count, 1)
        XCTAssertEqual(payload.reactionScores, ["love": 1])
        XCTAssertEqual(payload.reactionCounts, ["love": 1])
        XCTAssertEqual(payload.silent, true)
        XCTAssertNil(payload.shadowed)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:channel-ex7-63")
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.attachments.count, 2)
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
    }

    func test_messagePayload_isSerialized_withCustomExtraData() throws {
        let box = try JSONDecoder.default.decode(MessagePayload.Boxed.self, from: messageJSON)
        let payload = box.message

        XCTAssertEqual(payload.id, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.type, "regular")
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
        XCTAssertEqual(payload.parentId, "3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.showInChannel, true)
        XCTAssertEqual(payload.mentionedUsers.map(\.id), [])
        XCTAssertEqual(payload.threadParticipants?.map(\.id), ["josh", "vader"])
        XCTAssertEqual(payload.replyCount, 0)
        XCTAssertEqual(payload.custom, messageCustomData)
        XCTAssertEqual(payload.latestReactions.count, 1)
        XCTAssertEqual(payload.ownReactions.count, 1)
        XCTAssertEqual(payload.reactionScores, ["love": 1])
        XCTAssertEqual(payload.reactionCounts, ["love": 1])
        XCTAssertEqual(payload.silent, true)
        XCTAssertEqual(payload.shadowed, true)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:channel-ex7-63")
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.translations, [.italian: "si sono qui", .dutch: "ja ik ben hier"])
    }
    
    // MARK: - MessagePayload.asModel() Tests
    
    func test_messagePayload_asModel_convertsAllPropertiesCorrectly() {
        let messageId = "test-message-id"
        let cid = ChannelId(type: .messaging, id: "test-channel")
        let currentUserId = "current-user-id"
        let userPayload = UserPayload.dummy(userId: "author-user-id", name: "Test Author")
        let mentionedUserPayload = UserPayload.dummy(userId: "mentioned-user-id", name: "Mentioned User")
        let threadParticipantPayload = UserPayload.dummy(userId: "participant-user-id", name: "Thread Participant")
        let pinnedByPayload = UserPayload.dummy(userId: "pinned-by-user-id", name: "Pinned By User")
        let quotedMessagePayload = MessagePayload.dummy(messageId: "quoted-message-id", text: "Quoted message text")
        let reactionPayload = MessageReactionPayload(
            type: MessageReactionType(rawValue: "love"),
            score: 1,
            messageId: "123",
            createdAt: Date(timeIntervalSince1970: 1_609_459_300),
            updatedAt: Date(timeIntervalSince1970: 1_609_459_300),
            user: userPayload,
            extraData: [:]
        )
        
        let payload = MessagePayload(
            id: messageId,
            type: .regular,
            user: userPayload,
            createdAt: Date(timeIntervalSince1970: 1_609_459_200),
            updatedAt: Date(timeIntervalSince1970: 1_609_459_250),
            deletedAt: Date(timeIntervalSince1970: 1_609_459_300),
            text: "Test message text",
            command: "test-command",
            parentId: "parent-message-id",
            showReplyInChannel: true,
            quotedMessageId: "quoted-message-id",
            quotedMessage: quotedMessagePayload,
            mentionedUsers: [mentionedUserPayload],
            threadParticipants: [threadParticipantPayload],
            replyCount: 5,
            extraData: ["custom_field": .string("custom_value")],
            latestReactions: [reactionPayload],
            ownReactions: [reactionPayload],
            reactionScores: ["love": 1],
            reactionCounts: ["love": 1],
            reactionGroups: [:],
            isSilent: true,
            isShadowed: true,
            attachments: [],
            channel: nil,
            pinned: true,
            pinnedBy: pinnedByPayload,
            pinnedAt: Date(timeIntervalSince1970: 1_609_459_400),
            pinExpires: Date(timeIntervalSince1970: 1_609_459_500),
            translations: [.spanish: "Texto del mensaje de prueba"],
            originalLanguage: "en",
            moderation: nil,
            messageTextUpdatedAt: Date(timeIntervalSince1970: 1_609_459_350), poll: nil,
            reminder: nil,
            location: nil
        )
        
        let channelReads = [
            ChatChannelRead(
                lastReadAt: Date(timeIntervalSince1970: 1_609_459_600),
                lastReadMessageId: "read-message-id",
                unreadMessagesCount: 0,
                user: ChatUser.mock(
                    id: "reader-user-id",
                    name: "Reader User"
                )
            )
        ]

        let chatMessage = payload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channelReads)

        XCTAssertEqual(chatMessage.id, messageId)
        XCTAssertEqual(chatMessage.cid, cid)
        XCTAssertEqual(chatMessage.text, "Test message text")
        XCTAssertEqual(chatMessage.type, .regular)
        XCTAssertEqual(chatMessage.command, "test-command")
        XCTAssertEqual(chatMessage.createdAt, Date(timeIntervalSince1970: 1_609_459_200))
        XCTAssertEqual(chatMessage.updatedAt, Date(timeIntervalSince1970: 1_609_459_250))
        XCTAssertEqual(chatMessage.deletedAt, Date(timeIntervalSince1970: 1_609_459_300))
        XCTAssertNil(chatMessage.arguments)
        XCTAssertEqual(chatMessage.parentMessageId, "parent-message-id")
        XCTAssertEqual(chatMessage.showReplyInChannel, true)
        XCTAssertEqual(chatMessage.replyCount, 5)
        XCTAssertEqual(chatMessage.extraData, ["custom_field": .string("custom_value")])
        XCTAssertEqual(chatMessage.isSilent, true)
        XCTAssertEqual(chatMessage.isShadowed, true)
        XCTAssertEqual(chatMessage.reactionScores, ["love": 1])
        XCTAssertEqual(chatMessage.reactionCounts, ["love": 1])
        XCTAssertEqual(chatMessage.author.id, "author-user-id")
        XCTAssertEqual(chatMessage.mentionedUsers.first?.id, "mentioned-user-id")
        XCTAssertEqual(chatMessage.threadParticipants.first?.id, "participant-user-id")
        XCTAssertEqual(chatMessage.isSentByCurrentUser, false)
        XCTAssertNotNil(chatMessage.pinDetails)
        XCTAssertEqual(chatMessage.pinDetails?.pinnedAt, Date(timeIntervalSince1970: 1_609_459_400))
        XCTAssertEqual(chatMessage.pinDetails?.expiresAt, Date(timeIntervalSince1970: 1_609_459_500))
        XCTAssertEqual(chatMessage.pinDetails?.pinnedBy.id, "pinned-by-user-id")
        XCTAssertEqual(chatMessage.quotedMessage?.id, "quoted-message-id")
        XCTAssertEqual(chatMessage.translations, [.spanish: "Texto del mensaje de prueba"])
        XCTAssertEqual(chatMessage.originalLanguage?.languageCode, "en")
        XCTAssertEqual(chatMessage.textUpdatedAt, Date(timeIntervalSince1970: 1_609_459_350))
        XCTAssertEqual(chatMessage.latestReactions.count, 1)
        XCTAssertEqual(chatMessage.currentUserReactions.count, 1)
        XCTAssertFalse(chatMessage.isFlaggedByCurrentUser)
    }
    
    func test_messagePayload_asModel_withMinimalData_handlesCorrectly() {
        let messageId = "minimal-message-id"
        let cid = ChannelId(type: .messaging, id: "minimal-channel")
        let currentUserId = "current-user-id"
        let userPayload = UserPayload.dummy(userId: currentUserId, name: "Current User")
        let payload = MessagePayload(
            id: messageId,
            type: .regular,
            user: userPayload,
            createdAt: Date(timeIntervalSince1970: 1_609_459_200),
            updatedAt: Date(timeIntervalSince1970: 1_609_459_200),
            deletedAt: nil,
            text: "Minimal message",
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            quotedMessageId: nil,
            quotedMessage: nil,
            mentionedUsers: [],
            threadParticipants: [],
            replyCount: 0,
            extraData: [:],
            latestReactions: [],
            ownReactions: [],
            reactionScores: [:],
            reactionCounts: [:],
            reactionGroups: [:],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            channel: nil,
            pinned: false,
            pinnedBy: nil,
            pinnedAt: nil,
            pinExpires: nil,
            translations: nil,
            originalLanguage: nil,
            moderation: nil,
            messageTextUpdatedAt: nil,
            poll: nil,
            reminder: nil,
            location: nil
        )

        let chatMessage = payload.asModel(cid: cid, currentUserId: currentUserId, channelReads: [])

        XCTAssertEqual(chatMessage.id, messageId)
        XCTAssertEqual(chatMessage.cid, cid)
        XCTAssertEqual(chatMessage.text, "Minimal message")
        XCTAssertEqual(chatMessage.type, .regular)
        XCTAssertNil(chatMessage.command)
        XCTAssertEqual(chatMessage.createdAt, Date(timeIntervalSince1970: 1_609_459_200))
        XCTAssertEqual(chatMessage.updatedAt, Date(timeIntervalSince1970: 1_609_459_200))
        XCTAssertNil(chatMessage.deletedAt)
        XCTAssertNil(chatMessage.arguments)
        XCTAssertNil(chatMessage.parentMessageId)
        XCTAssertEqual(chatMessage.showReplyInChannel, false)
        XCTAssertEqual(chatMessage.replyCount, 0)
        XCTAssertEqual(chatMessage.extraData, [:])
        XCTAssertEqual(chatMessage.isSilent, false)
        XCTAssertEqual(chatMessage.isShadowed, false)
        XCTAssertEqual(chatMessage.reactionScores, [:])
        XCTAssertEqual(chatMessage.reactionCounts, [:])
        XCTAssertEqual(chatMessage.author.id, currentUserId)
        XCTAssertTrue(chatMessage.mentionedUsers.isEmpty)
        XCTAssertTrue(chatMessage.threadParticipants.isEmpty)
        XCTAssertTrue(chatMessage.isSentByCurrentUser)
        XCTAssertNil(chatMessage.pinDetails)
        XCTAssertNil(chatMessage.quotedMessage)
        XCTAssertNil(chatMessage.translations)
        XCTAssertNil(chatMessage.originalLanguage)
        XCTAssertNil(chatMessage.textUpdatedAt)
        XCTAssertTrue(chatMessage.latestReactions.isEmpty)
        XCTAssertTrue(chatMessage.currentUserReactions.isEmpty)
        XCTAssertFalse(chatMessage.isFlaggedByCurrentUser)
        XCTAssertTrue(chatMessage.readBy.isEmpty)
        XCTAssertTrue(chatMessage.allAttachments.isEmpty)
        XCTAssertTrue(chatMessage.latestReplies.isEmpty)
        XCTAssertNil(chatMessage.localState)
        XCTAssertNil(chatMessage.locallyCreatedAt)
        XCTAssertFalse(chatMessage.isBounced)
        XCTAssertNil(chatMessage.moderationDetails)
        XCTAssertNil(chatMessage.poll)
        XCTAssertNil(chatMessage.reminder)
        XCTAssertNil(chatMessage.sharedLocation)
    }

    // MARK: - deletedForMe Tests

    func test_messagePayload_asModel_deletedForMe_whenTrue() {
        let payload = MessagePayload.dummy(deletedForMe: true)

        let message = payload.asModel(
            cid: ChannelId(type: .messaging, id: "test"),
            currentUserId: "test-user",
            channelReads: []
        )

        XCTAssertEqual(message.deletedForMe, true)
    }

    func test_messagePayload_asModel_deletedForMe_whenFalse() {
        let payload = MessagePayload.dummy(deletedForMe: false)

        let message = payload.asModel(
            cid: ChannelId(type: .messaging, id: "test"),
            currentUserId: "test-user",
            channelReads: []
        )

        XCTAssertEqual(message.deletedForMe, false)
    }

    func test_messagePayload_asModel_deletedForMe_whenNil_defaultsToFalse() {
        let payload = MessagePayload.dummy(deletedForMe: nil)

        let message = payload.asModel(
            cid: ChannelId(type: .messaging, id: "test"),
            currentUserId: "test-user",
            channelReads: []
        )

        XCTAssertEqual(message.deletedForMe, false)
    }
}

final class MessageRequestBody_Tests: XCTestCase {
    func test_isSerialized() throws {
        let payload: MessageRequestBody = .init(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            type: nil,
            command: .unique,
            args: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            isSilent: true,
            quotedMessageId: "quoted-message-id",
            mentionedUserIds: [.unique],
            pinned: true,
            pinExpires: "2021-05-15T06:43:08.776Z".toDate(),
            restrictedVisibility: ["test"],
            extraData: ["secret_note": .string("Anakin is Vader ;-)")]
        )

        let serializedJSON = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "id": payload.id,
            "text": payload.text,
            "parent_id": payload.parentId!,
            "show_in_channel": true,
            "silent": true,
            "args": payload.args!,
            "quoted_message_id": "quoted-message-id",
            "mentioned_users": payload.mentionedUserIds,
            "secret_note": "Anakin is Vader ;-)",
            "command": payload.command!,
            "pinned": true,
            "pin_expires": "2021-05-15T06:43:08.776Z",
            "restricted_visibility": ["test"]
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }

    func test_isSerialized_withEnhancedMentions() throws {
        let payload: MessageRequestBody = .init(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            type: nil,
            showReplyInChannel: false,
            isSilent: false,
            mentionedUserIds: ["user-1"],
            mentionedHere: true,
            mentionedChannel: true,
            mentionedGroupIds: ["backendsupport"],
            mentionedRoles: ["admin"],
            extraData: [:]
        )

        let serializedJSON = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "id": payload.id,
            "text": payload.text,
            "show_in_channel": false,
            "silent": false,
            "pinned": false,
            "mentioned_users": ["user-1"],
            "mentioned_here": true,
            "mentioned_channel": true,
            "mentioned_group_ids": ["backendsupport"],
            "mentioned_roles": ["admin"]
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }

    func test_isSerialized_enhancedMentionsOmittedWhenEmpty() throws {
        let payload: MessageRequestBody = .init(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            type: nil,
            showReplyInChannel: false,
            isSilent: false,
            extraData: [:]
        )

        let serializedJSON = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "id": payload.id,
            "text": payload.text,
            "show_in_channel": false,
            "silent": false,
            "pinned": false
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }

    func test_isSerialized_whenSystemMessage() throws {
        let payload: MessageRequestBody = .init(
            id: .unique,
            user: .dummy(userId: .unique),
            text: "Announcement: The Death Star will be operational in 2 weeks.",
            type: MessageType.system.rawValue,
            extraData: [:]
        )

        let serializedJSON = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "id": payload.id,
            "text": payload.text,
            "type": "system",
            "silent": false,
            "pinned": false,
            "show_in_channel": false
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }

    /// Check whether the message body is serialized when `isSilent` is not provided in `init`
    func test_isSerializedWithoutSilent() throws {
        let payload: MessageRequestBody = .init(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            type: nil,
            command: .unique,
            args: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            quotedMessageId: "quoted-message-id",
            mentionedUserIds: [.unique],
            pinned: true,
            pinExpires: "2021-05-15T06:43:08.776Z".toDate(),
            extraData: ["secret_note": .string("Anakin is Vader ;-)")]
        )

        let serializedJSON = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "id": payload.id,
            "text": payload.text,
            "parent_id": payload.parentId!,
            "show_in_channel": true,
            "silent": false,
            "args": payload.args!,
            "quoted_message_id": "quoted-message-id",
            "mentioned_users": payload.mentionedUserIds,
            "secret_note": "Anakin is Vader ;-)",
            "command": payload.command!,
            "pinned": true,
            "pin_expires": "2021-05-15T06:43:08.776Z"
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])

        AssertJSONEqual(serializedJSON, expectedJSON)
    }
}

final class MessageRepliesPayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        let mockJSON = XCTestCase.mockData(fromJSONFile: "Messages")
        let payload = try JSONDecoder.default.decode(MessageRepliesPayload.self, from: mockJSON)

        // Assert 2 messages successfully decoded.
        XCTAssertTrue(payload.messages.count == 2)
    }
}

final class MessageReactionsPayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        let mockJSON = XCTestCase.mockData(fromJSONFile: "MessageReactionsPayload")
        let payload = try JSONDecoder.default.decode(MessageReactionsPayload.self, from: mockJSON)

        // Assert 2 reactions successfully decoded.
        XCTAssertTrue(payload.reactions.count == 2)
    }
}
