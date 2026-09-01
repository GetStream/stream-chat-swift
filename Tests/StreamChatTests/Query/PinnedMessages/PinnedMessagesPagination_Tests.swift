//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamCore
import XCTest

final class PinnedMessagesPagination_Tests: XCTestCase {
    // MARK: - ID around

    func test_aroundMessage_isEncodedCorrectly() throws {
        // Create message id
        let messageId: MessageId = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .aroundMessage(messageId)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        AssertJSONEqual(json, ["id_around": messageId])
    }

    // MARK: - ID before

    func test_beforeMessageInclusive_isEncodedCorrectly() throws {
        // Create message id
        let messageId: MessageId = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .before(messageId, inclusive: true)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        AssertJSONEqual(json, ["id_lte": messageId])
    }

    func test_beforeMessageExclusive_isEncodedCorrectly() throws {
        // Create message id
        let messageId: MessageId = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .before(messageId, inclusive: false)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        AssertJSONEqual(json, ["id_lt": messageId])
    }

    // MARK: - ID after

    func test_afterMessageInclusive_isEncodedCorrectly() throws {
        // Create message id
        let messageId: MessageId = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .after(messageId, inclusive: true)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        AssertJSONEqual(json, ["id_gte": messageId])
    }

    func test_afterMessageExclusive_isEncodedCorrectly() throws {
        // Create message id
        let messageId: MessageId = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .after(messageId, inclusive: false)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        AssertJSONEqual(json, ["id_gt": messageId])
    }

    // MARK: - Timestamp around

    func test_aroundTimestamp_isEncodedCorrectly() throws {
        // Create timestamp
        let timestamp: Date = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .aroundTimestamp(timestamp)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        let timestampString = try XCTUnwrap(DateFormatter.Stream.rfc3339DateString(from: timestamp))
        AssertJSONEqual(json, ["pinned_at_around": timestampString])
    }

    // MARK: - Timestamp earlier

    func test_earlierTimestampInclusive_isEncodedCorrectly() throws {
        // Create timestamp
        let timestamp: Date = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .earlier(timestamp, inclusive: true)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        let timestampString = try XCTUnwrap(DateFormatter.Stream.rfc3339DateString(from: timestamp))
        AssertJSONEqual(json, ["pinned_at_before_or_equal": timestampString])
    }

    func test_earlierTimestampExclusive_isEncodedCorrectly() throws {
        // Create timestamp
        let timestamp: Date = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .earlier(timestamp, inclusive: false)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        let timestampString = try XCTUnwrap(DateFormatter.Stream.rfc3339DateString(from: timestamp))
        AssertJSONEqual(json, ["pinned_at_before": timestampString])
    }

    // MARK: - Timestamp later

    func test_laterTimestampInclusive_isEncodedCorrectly() throws {
        // Create timestamp
        let timestamp: Date = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .later(timestamp, inclusive: true)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        let timestampString = try XCTUnwrap(DateFormatter.Stream.rfc3339DateString(from: timestamp))
        AssertJSONEqual(json, ["pinned_at_after_or_equal": timestampString])
    }

    func test_laterTimestampExclusive_isEncodedCorrectly() throws {
        // Create timestamp
        let timestamp: Date = .unique

        // Create pagination
        let pagination: PinnedMessagesPagination = .later(timestamp, inclusive: false)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        let timestampString = try XCTUnwrap(DateFormatter.Stream.rfc3339DateString(from: timestamp))
        AssertJSONEqual(json, ["pinned_at_after": timestampString])
    }

    // MARK: - Offset

    func test_offset_isEncodedCorrectly() throws {
        // Create offset
        let offset = 25

        // Create pagination
        let pagination: PinnedMessagesPagination = .offset(offset)

        // Create JSON pagination.
        let json = try JSONEncoder.default.encode(pagination)

        // Assert encoding is correct.
        AssertJSONEqual(json, ["offset": offset])
    }

    // MARK: - Convenience Properties

    func test_aroundMessageId_returnsMatchingValue() {
        let messageId = MessageId.unique

        XCTAssertEqual(PinnedMessagesPagination.aroundMessage(messageId).aroundMessageId, messageId)
        XCTAssertNil(PinnedMessagesPagination.after(messageId, inclusive: true).aroundMessageId)
    }

    func test_messageIdAfterOrEqual_returnsMatchingValue() {
        let messageId = MessageId.unique

        XCTAssertEqual(PinnedMessagesPagination.after(messageId, inclusive: true).messageIdAfterOrEqual, messageId)
        XCTAssertNil(PinnedMessagesPagination.after(messageId, inclusive: false).messageIdAfterOrEqual)
    }

    func test_messageIdAfter_returnsMatchingValue() {
        let messageId = MessageId.unique

        XCTAssertEqual(PinnedMessagesPagination.after(messageId, inclusive: false).messageIdAfter, messageId)
        XCTAssertNil(PinnedMessagesPagination.after(messageId, inclusive: true).messageIdAfter)
    }

    func test_messageIdBeforeOrEqual_returnsMatchingValue() {
        let messageId = MessageId.unique

        XCTAssertEqual(PinnedMessagesPagination.before(messageId, inclusive: true).messageIdBeforeOrEqual, messageId)
        XCTAssertNil(PinnedMessagesPagination.before(messageId, inclusive: false).messageIdBeforeOrEqual)
    }

    func test_messageIdBefore_returnsMatchingValue() {
        let messageId = MessageId.unique

        XCTAssertEqual(PinnedMessagesPagination.before(messageId, inclusive: false).messageIdBefore, messageId)
        XCTAssertNil(PinnedMessagesPagination.before(messageId, inclusive: true).messageIdBefore)
    }

    func test_aroundTimestamp_returnsMatchingValue() {
        let timestamp = Date.unique

        XCTAssertEqual(PinnedMessagesPagination.aroundTimestamp(timestamp).aroundTimestamp, timestamp)
        XCTAssertNil(PinnedMessagesPagination.later(timestamp, inclusive: true).aroundTimestamp)
    }

    func test_timestampAfterOrEqual_returnsMatchingValue() {
        let timestamp = Date.unique

        XCTAssertEqual(PinnedMessagesPagination.later(timestamp, inclusive: true).timestampAfterOrEqual, timestamp)
        XCTAssertNil(PinnedMessagesPagination.later(timestamp, inclusive: false).timestampAfterOrEqual)
    }

    func test_timestampAfter_returnsMatchingValue() {
        let timestamp = Date.unique

        XCTAssertEqual(PinnedMessagesPagination.later(timestamp, inclusive: false).timestampAfter, timestamp)
        XCTAssertNil(PinnedMessagesPagination.later(timestamp, inclusive: true).timestampAfter)
    }

    func test_timestampBeforeOrEqual_returnsMatchingValue() {
        let timestamp = Date.unique

        XCTAssertEqual(PinnedMessagesPagination.earlier(timestamp, inclusive: true).timestampBeforeOrEqual, timestamp)
        XCTAssertNil(PinnedMessagesPagination.earlier(timestamp, inclusive: false).timestampBeforeOrEqual)
    }

    func test_timestampBefore_returnsMatchingValue() {
        let timestamp = Date.unique

        XCTAssertEqual(PinnedMessagesPagination.earlier(timestamp, inclusive: false).timestampBefore, timestamp)
        XCTAssertNil(PinnedMessagesPagination.earlier(timestamp, inclusive: true).timestampBefore)
    }

    func test_offset_returnsMatchingValue() {
        let offset = 25

        XCTAssertEqual(PinnedMessagesPagination.offset(offset).offset, offset)
        XCTAssertNil(PinnedMessagesPagination.aroundMessage(.unique).offset)
    }
}
