//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AttachmentId_Tests: XCTestCase {
    func test_init_assignsValuesCorrectly() {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let index: Int = .random(in: 0..<1000)

        // Create `AttachmentId`
        let id = AttachmentId(
            cid: cid,
            messageId: messageId,
            index: index
        )

        // Assert values are assigned correctly
        XCTAssertEqual(id.cid, cid)
        XCTAssertEqual(id.messageId, messageId)
        XCTAssertEqual(id.index, index)
    }

    func test_rawValue() {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let index: Int = .random(in: 0..<1000)

        // Create `AttachmentId`
        let id = AttachmentId(
            cid: cid,
            messageId: messageId,
            index: index
        )

        // Assert values are assigned correctly
        XCTAssertEqual(id.rawValue, [cid.rawValue, messageId, String(index)].joined(separator: AttachmentId.separator))
    }

    func test_init_rawValue_failsWhenRawValueIsInvalid() {
        let invalidRawValues: [String] = [
            // # of components < 3
            "asdas:asdasda/asdasda",
            // # of components > 3
            "asdas:asdasda/asdasda/1/12312",
            // Invalid index
            "asdas:asdasda/asdasda/as",
            // Invalid separator
            "asdas:asdasda|asdasda|as",
            // Invalid cid format
            "asdas|asdasda|as"
        ]

        invalidRawValues.forEach {
            XCTAssertNil(AttachmentId(rawValue: $0))
        }
    }

    func test_init_rawValue_assignsValuesCorrectly() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let index: Int = .random(in: 0..<1000)

        // Create if using `init(rawValue: )`
        let id = try XCTUnwrap(
            AttachmentId(rawValue: [cid.rawValue, messageId, String(index)].joined(separator: AttachmentId.separator))
        )

        // Assert values are assigned correctly
        XCTAssertEqual(id.cid, cid)
        XCTAssertEqual(id.messageId, messageId)
        XCTAssertEqual(id.index, index)
    }
}
