//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class MessagePayload_Tests: XCTestCase {
    let messageJSON = XCTestCase.mockData(fromFile: "Message")
    let messageJSONWithCorruptedAttachments = XCTestCase.mockData(fromFile: "MessageWithBrokenAttachments")
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
        XCTAssertEqual(payload.isSilent, true)
        XCTAssertEqual(payload.isShadowed, true)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:channel-ex7-63")
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
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
        XCTAssertEqual(payload.isSilent, true)
        XCTAssertEqual(payload.isShadowed, true)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:channel-ex7-63")
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
    }
}

class MessageRequestBody_Tests: XCTestCase {
    func test_isSerialized() throws {
        let payload: MessageRequestBody = .init(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            command: .unique,
            args: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            isSilent: true,
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
            "silent": true,
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
    
    /// Check whether the message body is serialized when `isSilent` is not provided in `init`
    func test_isSerializedWithoutSilent() throws {
        let payload: MessageRequestBody = .init(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
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

class MessageRepliesPayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        let mockJSON = XCTestCase.mockData(fromFile: "Messages")
        let payload = try JSONDecoder.default.decode(MessageRepliesPayload.self, from: mockJSON)
        
        // Assert 2 messages successfully decoded.
        XCTAssertTrue(payload.messages.count == 2)
    }
}
