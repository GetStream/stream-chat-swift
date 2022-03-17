//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
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
}
