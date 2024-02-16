//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessagePayload_Tests: XCTestCase {
    let messageJSON = XCTestCase.mockData(fromJSONFile: "Message")
    let messageJSONWithCorruptedAttachments = XCTestCase.mockData(fromJSONFile: "MessageWithBrokenAttachments")
    let messageCustomData: [String: RawJSON] = ["secret_note": .string("Anakin is Vader!")]

    func test_messagePayload_isSerialized_withDefaultExtraData() throws {
        let box = try JSONDecoder.stream.decode(Message.Boxed.self, from: messageJSON)
        let payload = box.message

        XCTAssertEqual(payload.id, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.type, "regular")
        XCTAssertEqual(payload.user?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
//        XCTAssertEqual(payload.args, nil)
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
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.i18n, ["it": "si sono qui", "nl": "ja ik ben hier"])
//        XCTAssertEqual(payload.language, "it")
//        XCTAssertEqual(payload.moderationDetails?.action, "MESSAGE_RESPONSE_ACTION_BOUNCE")
//        XCTAssertEqual(payload.moderationDetails?.originalText, "click here to win a new iphone!!")
    }

    func test_messagePayload_isSerialized_withDefaultExtraData_withBrokenAttachmentPayload() throws {
        let box = try JSONDecoder.default.decode(Message.Boxed.self, from: messageJSONWithCorruptedAttachments)
        let payload = box.message

        var messageCustomData = self.messageCustomData
        messageCustomData["tau"] = .double(6.28)

        XCTAssertEqual(payload.id, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.type, "regular")
        XCTAssertEqual(payload.user?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
//        XCTAssertEqual(payload.args, nil)
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
        XCTAssertEqual(payload.shadowed, false)
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.attachments.count, 2)
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
    }

    func test_messagePayload_isSerialized_withCustomExtraData() throws {
        let box = try JSONDecoder.default.decode(Message.Boxed.self, from: messageJSON)
        let payload = box.message

        XCTAssertEqual(payload.id, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.type, "regular")
        XCTAssertEqual(payload.user?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.createdAt, "2020-07-16T15:39:03.010717Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.895109Z".toDate())
        XCTAssertEqual(payload.deletedAt, "2020-07-16T15:55:03.010717Z".toDate())
        XCTAssertEqual(payload.text, "No, I am your father!")
        XCTAssertEqual(payload.command, nil)
//        XCTAssertEqual(payload.args, nil)
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
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.pinned, true)
        XCTAssertEqual(payload.pinnedAt, "2021-04-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinExpires, "2021-05-15T06:43:08.776911Z".toDate())
        XCTAssertEqual(payload.pinnedBy?.id, "broken-waterfall-5")
        XCTAssertEqual(payload.quotedMessageId, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
        XCTAssertEqual(payload.i18n, ["it": "si sono qui", "nl": "ja ik ben hier"])
    }
}

final class MessageRepliesPayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        let mockJSON = XCTestCase.mockData(fromJSONFile: "Messages")
        let payload = try JSONDecoder.default.decode(GetRepliesResponse.self, from: mockJSON)

        // Assert 2 messages successfully decoded.
        XCTAssertTrue(payload.messages.count == 2)
    }
}

final class MessageReactionsPayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        let mockJSON = XCTestCase.mockData(fromJSONFile: "MessageReactionsPayload")
        let payload = try JSONDecoder.default.decode(GetReactionsResponse.self, from: mockJSON)

        // Assert 2 reactions successfully decoded.
        XCTAssertTrue(payload.reactions.count == 2)
    }
}
