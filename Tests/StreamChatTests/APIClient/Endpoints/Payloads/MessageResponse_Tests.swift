//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageResponse_Tests: XCTestCase {
    // MARK: - Conversion drift guards

    //
    // MessageWithChannelResponse and SearchResultMessage mirror MessageResponse
    // field by field in hand-written converters. Decoding all types from the same
    // fixture and comparing the converted encoding against a directly decoded
    // MessageResponse catches converters that fall behind the generated models.

    func test_messageWithChannelResponse_asMessageResponse_hasNoFieldDrift() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageResponseWithCustom")

        let source = try JSONDecoder.default.decode(MessageWithChannelResponse.self, from: json)
        let direct = try JSONDecoder.default.decode(MessageResponse.self, from: json)

        let convertedJSON = try encodedDictionary(source.asMessageResponse)
        let directJSON = try encodedDictionary(direct)

        XCTAssertEqual(convertedJSON, directJSON)
    }

    func test_searchResultMessage_asMessageResponse_hasNoFieldDrift() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageResponseWithCustom")

        let source = try JSONDecoder.default.decode(SearchResultMessage.self, from: json)
        let direct = try JSONDecoder.default.decode(MessageResponse.self, from: json)

        let convertedJSON = try encodedDictionary(source.asMessageResponse)
        let directJSON = try encodedDictionary(direct)

        XCTAssertEqual(convertedJSON, directJSON)
    }

    private func encodedDictionary(_ value: some Encodable) throws -> [String: RawJSON] {
        let data = try JSONEncoder.default.encode(value)
        return try XCTUnwrap(JSONDecoder.default.decode(RawJSON.self, from: data).dictionaryValue)
    }
}
