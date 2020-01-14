//
//  StringExtensionsTests.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 14/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest

final class StringExtensionsTests: TestCase {

    func testExample() {
        [("ab.cd", true),
         (".abcd", false),
         ("a.bcd", false),
         ("abc.d", false),
         ("abcd.", false),
         ("1a.cd", false),
         ("a1.cd", true),
         ("a1.1d", false),
         ("a1.a2", false),
         ("ab.com", true),
         ("ab.com\n", true),
         ("ab.com/", true),
         ("ab.cc ab.com/?asd", true),
         ("домен.ру", true)]
            .forEach { XCTAssertEqual($0.0.probablyHasURL, $0.1) }
    }
}
