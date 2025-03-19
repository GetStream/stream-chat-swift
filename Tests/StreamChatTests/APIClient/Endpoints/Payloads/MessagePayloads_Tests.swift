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

final class ReminderPayload_Tests: XCTestCase {
    let reminderJSON = XCTestCase.mockData(fromJSONFile: "ReminderPayload")
    
    func test_reminderPayload_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(ReminderPayload.self, from: reminderJSON)
        
        // Test basic properties
        XCTAssertEqual(payload.channelCid.rawValue, "messaging:26D82FB1-5")
        XCTAssertEqual(payload.messageId, "lando_calrissian-8tnV2qn0umMogef2WjR4k")
        XCTAssertNil(payload.remindAt) // Updated to nil as per new JSON
        XCTAssertEqual(payload.createdAt, "2025-03-19T00:38:38.697482729Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2025-03-19T00:38:38.697482729Z".toDate())
        
        // Test embedded message
        XCTAssertNotNil(payload.message)
        XCTAssertEqual(payload.message?.id, "lando_calrissian-8tnV2qn0umMogef2WjR4k")
        XCTAssertEqual(payload.message?.text, "4")
        XCTAssertEqual(payload.message?.type.rawValue, "regular")
        XCTAssertEqual(payload.message?.user.id, "lando_calrissian")
        XCTAssertEqual(payload.message?.createdAt, "2025-03-04T14:33:10.628163Z".toDate())
        XCTAssertEqual(payload.message?.updatedAt, "2025-03-04T14:33:10.628163Z".toDate())
        
        // Test channel properties (new in updated JSON)
        XCTAssertNotNil(payload.channel)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:26D82FB1-5")
        XCTAssertEqual(payload.channel?.name, "Yo")
    }
}

final class ReminderResponsePayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        // Create a JSON representation of a ReminderResponsePayload
        // with the updated structure including duration
        let reminderResponseJSON = """
        {
            "duration": "30.74ms",
            "reminder": {
                "channel_cid": "messaging:26D82FB1-5",
                "message_id": "lando_calrissian-8tnV2qn0umMogef2WjR4k",
                "remind_at": null,
                "created_at": "2025-03-19T00:38:38.697482729Z",
                "updated_at": "2025-03-19T00:38:38.697482729Z",
                "user_id": "han_solo"
            }
        }
        """.data(using: .utf8)!
        
        let payload = try JSONDecoder.default.decode(ReminderResponsePayload.self, from: reminderResponseJSON)
        
        XCTAssertEqual(payload.reminder.channelCid.rawValue, "messaging:26D82FB1-5")
        XCTAssertEqual(payload.reminder.messageId, "lando_calrissian-8tnV2qn0umMogef2WjR4k")
        XCTAssertNil(payload.reminder.remindAt)
        XCTAssertEqual(payload.reminder.createdAt, "2025-03-19T00:38:38.697482729Z".toDate())
        XCTAssertEqual(payload.reminder.updatedAt, "2025-03-19T00:38:38.697482729Z".toDate())
    }
}

final class RemindersQueryPayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        // Create a JSON representation of a RemindersQueryPayload with updated structure
        let remindersQueryJSON = """
        {
            "duration": "30.74ms",
            "reminders": [
                {
                    "channel_cid": "messaging:26D82FB1-5",
                    "message_id": "lando_calrissian-8tnV2qn0umMogef2WjR4k",
                    "remind_at": null,
                    "created_at": "2025-03-19T00:38:38.697482729Z",
                    "updated_at": "2025-03-19T00:38:38.697482729Z",
                    "user_id": "han_solo"
                },
                {
                    "channel_cid": "messaging:456",
                    "message_id": "message-456",
                    "remind_at": "2023-02-01T12:00:00.000Z",
                    "created_at": "2022-02-03T00:00:00.000Z",
                    "updated_at": "2022-02-03T00:00:00.000Z",
                    "user_id": "luke_skywalker"
                }
            ],
            "next": "next-page-token",
        }
        """.data(using: .utf8)!
        
        let payload = try JSONDecoder.default.decode(RemindersQueryPayload.self, from: remindersQueryJSON)
        
        // Verify the count of reminders
        XCTAssertEqual(payload.reminders.count, 2)
        
        // Verify pagination tokens
        XCTAssertEqual(payload.next, "next-page-token")
        
        // Verify first reminder details
        XCTAssertEqual(payload.reminders[0].channelCid.rawValue, "messaging:26D82FB1-5")
        XCTAssertEqual(payload.reminders[0].messageId, "lando_calrissian-8tnV2qn0umMogef2WjR4k")
        XCTAssertNil(payload.reminders[0].remindAt)
        
        // Verify second reminder details
        XCTAssertEqual(payload.reminders[1].channelCid.rawValue, "messaging:456")
        XCTAssertEqual(payload.reminders[1].messageId, "message-456")
        XCTAssertEqual(payload.reminders[1].remindAt, "2023-02-01T12:00:00.000Z".toDate())
    }
}
