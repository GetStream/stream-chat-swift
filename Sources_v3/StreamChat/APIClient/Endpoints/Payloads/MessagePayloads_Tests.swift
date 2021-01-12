//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class MessagePayload_Tests: XCTestCase {
    let messageJSON = XCTestCase.mockData(fromFile: "Message")
    
    func test_messagePayload_isSerialized_withDefaultExtraData() throws {
        let box = try JSONDecoder.default.decode(MessagePayload<DefaultExtraData>.Boxed.self, from: messageJSON)
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
        XCTAssertEqual(payload.threadParticipants.map(\.id), ["josh"])
        XCTAssertEqual(payload.replyCount, 0)
        XCTAssertEqual(payload.extraData, .defaultValue)
        XCTAssertEqual(payload.latestReactions.count, 1)
        XCTAssertEqual(payload.ownReactions.count, 1)
        XCTAssertEqual(payload.reactionScores, ["love": 1])
        XCTAssertEqual(payload.isSilent, true)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:channel-ex7-63")
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
    }
    
    func test_messagePayload_isSerialized_withCustomExtraData() throws {
        let box = try JSONDecoder.default.decode(MessagePayload<CustomData>.Boxed.self, from: messageJSON)
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
        XCTAssertEqual(payload.threadParticipants.map(\.id), ["josh"])
        XCTAssertEqual(payload.replyCount, 0)
        XCTAssertEqual(payload.extraData, TestExtraMessageData(secretNote: "Anakin is Vader!"))
        XCTAssertEqual(payload.latestReactions.count, 1)
        XCTAssertEqual(payload.ownReactions.count, 1)
        XCTAssertEqual(payload.reactionScores, ["love": 1])
        XCTAssertEqual(payload.isSilent, true)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:channel-ex7-63")
        XCTAssertEqual(payload.quotedMessage?.id, "4C0CC2DA-8AB5-421F-808E-50DC7E40653D")
    }
}

class MessageRequestBody_Tests: XCTestCase {
    func test_isSerialized() throws {
        let payload: MessageRequestBody<CustomData> = .init(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            command: .unique,
            args: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            quotedMessageId: "quoted-message-id",
            extraData: .init(secretNote: "Anakin is Vader ;-)")
        )
        
        let serialized = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "id": payload.id,
            "text": payload.text,
            "parent_id": payload.parentId!,
            "show_in_channel": true,
            "args": payload.args!,
            "quoted_message_id": "quoted-message-id",
            "secret_note": "Anakin is Vader ;-)",
            "command": payload.command!
        ]
        
        AssertJSONEqual(serialized, expected)
    }
}

class MessageRepliesPayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        let mockJSON = XCTestCase.mockData(fromFile: "Messages")
        let payload = try JSONDecoder.default.decode(MessageRepliesPayload<CustomData>.self, from: mockJSON)
        
        // Assert 2 messages successfully decoded.
        XCTAssertTrue(payload.messages.count == 2)
    }
}

private struct TestExtraMessageData: MessageExtraData {
    static var defaultValue: Self = .init(secretNote: "no secrets")
    
    let secretNote: String
    private enum CodingKeys: String, CodingKey {
        case secretNote = "secret_note"
    }
}

private enum CustomData: ExtraDataTypes {
    typealias Message = TestExtraMessageData
}
