//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessagePayload_Tests: XCTestCase {
    let messageJSON = XCTestCase.mockData(fromJSONFile: "Message")
    let messageJSONWithCorruptedAttachments = XCTestCase.mockData(fromJSONFile: "MessageWithBrokenAttachments")
    let messageCustomData: [String: RawJSON] = ["secret_note": .string("Anakin is Vader!")]

    func test_messagePayload_isSerialized_withDefaultExtraData() throws {
        let box = try JSONDecoder.stream.decode(MessagePayload.Boxed.self, from: messageJSON)
        let payload = box.message

        XCTAssertEqual(payload.id, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.type.rawValue, "regular")
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.messageTextUpdatedAt, "2023-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
        XCTAssertEqual(payload.args, nil)
        XCTAssertEqual(payload.parentId, "3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.showReplyInChannel, true)
        XCTAssertEqual(payload.mentionedUsers.map(\.id), [])
        XCTAssertEqual(payload.threadParticipants.map(\.id), ["josh", "vader"])
        XCTAssertEqual(payload.replyCount, 0)
        XCTAssertEqual(payload.extraData, messageCustomData)
        XCTAssertEqual(payload.latestReactions.count, 1)
        XCTAssertEqual(payload.ownReactions.count, 1)
        XCTAssertEqual(payload.reactionScores, ["love": 1])
        XCTAssertEqual(payload.reactionCounts, ["love": 1])
        XCTAssertEqual(payload.reactionGroups, [
            "love": MessageReactionGroupPayload(
                sumScores: 1,
                count: 1,
                firstReactionAt: "2024-04-17T13:14:53.643826Z".toDate(),
                lastReactionAt: "2024-04-17T13:15:53.643826Z".toDate()
            )
        ])
        XCTAssertEqual(payload.isSilent, true)
        XCTAssertEqual(payload.isShadowed, true)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:channel-ex7-63")
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.translations, [.italian: "si sono qui", .dutch: "ja ik ben hier"])
        XCTAssertEqual(payload.originalLanguage, "it")
        XCTAssertEqual(payload.moderationDetails?.action, "MESSAGE_RESPONSE_ACTION_BOUNCE")
        XCTAssertEqual(payload.moderationDetails?.originalText, "click here to win a new iphone!!")
        XCTAssertEqual(payload.moderation?.action, "bounce")
        XCTAssertEqual(payload.moderation?.originalText, "The message original text")
        XCTAssertEqual(payload.moderation?.textHarms, ["sexual_harrassment", "self_harm"])
        XCTAssertEqual(payload.moderation?.imageHarms, ["nudity"])
        XCTAssertEqual(payload.moderation?.blocklistMatched, "profanity_2021_01")
        XCTAssertEqual(payload.moderation?.semanticFilterMatched, "bad_phrases")
        XCTAssertEqual(payload.moderation?.platformCircumvented, false)
        XCTAssertEqual(payload.member?.channelRole, .moderator)
    }

    func test_messagePayload_isSerialized_withDefaultExtraData_withBrokenAttachmentPayload() throws {
        let box = try JSONDecoder.default.decode(MessagePayload.Boxed.self, from: messageJSONWithCorruptedAttachments)
        let payload = box.message

        var messageCustomData = self.messageCustomData
        messageCustomData["tau"] = .double(6.28)

        XCTAssertEqual(payload.id, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.type.rawValue, "regular")
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
        XCTAssertEqual(payload.args, nil)
        XCTAssertEqual(payload.parentId, "3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.showReplyInChannel, true)
        XCTAssertEqual(payload.mentionedUsers.map(\.id), [])
        XCTAssertEqual(payload.threadParticipants.map(\.id), ["josh"])
        XCTAssertEqual(payload.replyCount, 0)
        XCTAssertEqual(payload.extraData, messageCustomData)
        XCTAssertEqual(payload.latestReactions.count, 1)
        XCTAssertEqual(payload.ownReactions.count, 1)
        XCTAssertEqual(payload.reactionScores, ["love": 1])
        XCTAssertEqual(payload.reactionCounts, ["love": 1])
        XCTAssertEqual(payload.isSilent, true)
        XCTAssertEqual(payload.isShadowed, false)
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
        XCTAssertEqual(payload.type.rawValue, "regular")
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
        XCTAssertEqual(payload.args, nil)
        XCTAssertEqual(payload.parentId, "3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.showReplyInChannel, true)
        XCTAssertEqual(payload.mentionedUsers.map(\.id), [])
        XCTAssertEqual(payload.threadParticipants.map(\.id), ["josh", "vader"])
        XCTAssertEqual(payload.replyCount, 0)
        XCTAssertEqual(payload.extraData, messageCustomData)
        XCTAssertEqual(payload.latestReactions.count, 1)
        XCTAssertEqual(payload.ownReactions.count, 1)
        XCTAssertEqual(payload.reactionScores, ["love": 1])
        XCTAssertEqual(payload.reactionCounts, ["love": 1])
        XCTAssertEqual(payload.isSilent, true)
        XCTAssertEqual(payload.isShadowed, true)
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
            args: "test-args",
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
            moderationDetails: nil,
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
        XCTAssertEqual(chatMessage.arguments, "test-args")
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
            moderationDetails: nil,
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
