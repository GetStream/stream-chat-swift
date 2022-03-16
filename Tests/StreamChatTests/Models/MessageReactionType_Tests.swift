//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageReactionType_Tests: XCTestCase {
    func test_init_rawValue() {
        let value: String = .unique
        let reaction = MessageReactionType(rawValue: value)
        XCTAssertEqual(reaction.rawValue, value)
    }
    
    func test_init_stringLiteral() {
        let reaction: MessageReactionType = "like"
        XCTAssertEqual(reaction.rawValue, "like")
    }
    
    func test_reaction_isEncodedCorrectly() throws {
        let encoder = JSONEncoder.default

        // Create the reaction.
        let reaction = MessageReactionType(rawValue: .unique)
        
        // Assert reaction is encoded as a string
        XCTAssertEqual(encoder.encodedString(reaction), reaction.rawValue)
    }
    
    func test_reaction_isDecodedCorrectly() throws {
        // Create the reaction.
        let reaction = MessageReactionType(rawValue: .unique)
        
        // Assert reaction is decoded correctly.
        XCTAssertEqual(decode(value: reaction.rawValue), reaction)
    }
    
    @available(iOS, deprecated: 12.0, message: "Remove this workaround when dropping iOS 12 support.")
    private func decode(value: String) -> MessageReactionType? {
        // We must decode it as a part of JSON because older iOS version don't support JSON fragments
        let key = String.unique
        let jsonString = #"{ "\#(key)" : "\#(value)"}"#
        let data = jsonString.data(using: .utf8)!
        let serializedJSON = try? JSONDecoder.stream.decode([String: MessageReactionType].self, from: data)
        return serializedJSON?[key]
    }
}
