//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatUI
import XCTest

final class String_Extensions_Tests: XCTestCase {
    func test_onlyEmoji() {
        XCTAssertTrue("🍺".isSingleEmoji)
    }
    
    func test_stringWithEmoji() {
        XCTAssertFalse("Cold one 🍺".isSingleEmoji)
    }
    
    func test_multipleEmoji() {
        XCTAssertFalse("😄😆".isSingleEmoji)
    }
    
    func test_skinToneEmoji() {
        XCTAssertTrue("👋🏽".isSingleEmoji)
    }
    
    func test_multiScalarCharacterEmoji() {
        XCTAssertTrue("1️⃣".isSingleEmoji) // 3 UnicodeScalars
        XCTAssertTrue("👨‍👩‍👧‍👦".isSingleEmoji) // 7 UnicodeScalars
    }
    
    func test_containsEmoji() {
        let string = "Hello 👋🏽"
        XCTAssertTrue(string.containsEmoji)
        XCTAssertFalse(string.containsOnlyEmoji)
    }
    
    func test_containsOnlyEmoji() {
        XCTAssertTrue("💯😆☺️".containsOnlyEmoji)
        XCTAssertFalse("Number one 1️⃣".containsOnlyEmoji)
    }

    func test_nonEmojiScalar() {
        XCTAssertFalse("3".containsEmoji)
        XCTAssertFalse("#".containsEmoji)
    }
    
    func test_Levenshtein() throws {
        XCTAssertEqual("".levenshtein(""), "".levenshtein(""))
        XCTAssertEqual("".levenshtein(""), 0)
        XCTAssertEqual("a".levenshtein(""), 1)
        XCTAssertEqual("".levenshtein("a"), 1)
        XCTAssertEqual("tommaso".levenshtein("ToMmAsO"), 4)
    }
}
