//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Codable_Extensions_Tests: XCTestCase {
    func test_decodeRawJSON_whenDataIsNil_returnsEmptyDictionary() throws {
        let result = try JSONDecoder.stream.decodeRawJSON(from: nil)
        XCTAssertEqual(result, [:])
    }

    func test_decodeRawJSON_whenDataIsEmpty_returnsEmptyDictionary() throws {
        let result = try JSONDecoder.stream.decodeRawJSON(from: Data())
        XCTAssertEqual(result, [:])
    }

    /// This is the exact byte sequence `JSONEncoder` produces for an empty `[String: RawJSON]`, and the one
    /// persisted for entities with no custom fields. It should take the fast path instead of a full decode.
    func test_decodeRawJSON_whenDataIsEmptyJSONObject_returnsEmptyDictionaryWithoutDecoding() throws {
        let data = Data("{}".utf8)
        let result = try JSONDecoder.stream.decodeRawJSON(from: data)
        XCTAssertEqual(result, [:])
    }

    func test_decodeRawJSON_whenDataHasFields_decodesThem() throws {
        let data = Data(#"{"is_moderator":true,"nickname":"scrappy"}"#.utf8)
        let result = try JSONDecoder.stream.decodeRawJSON(from: data)
        XCTAssertEqual(result, [
            "is_moderator": .bool(true),
            "nickname": .string("scrappy")
        ])
    }

    func test_decodeRawJSON_whenDataIsInvalidJSON_throws() {
        let data = Data("not json".utf8)
        XCTAssertThrowsError(try JSONDecoder.stream.decodeRawJSON(from: data))
    }

    /// Round-trips through the encoder actually used to persist extra data, to guard the fast path's assumption
    /// that an empty dictionary is always encoded as the literal `{}` bytes.
    func test_decodeRawJSON_roundTripsWithEncoderUsedForPersistedExtraData() throws {
        let encoded = try JSONEncoder.default.encode([String: RawJSON]())
        XCTAssertEqual(encoded, Data("{}".utf8))

        let result = try JSONDecoder.stream.decodeRawJSON(from: encoded)
        XCTAssertEqual(result, [:])
    }
}
