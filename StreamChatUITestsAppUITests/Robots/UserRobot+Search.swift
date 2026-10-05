//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// MARK: Actions

extension UserRobot {
    @discardableResult
    func search(_ text: String) -> Self {
        SearchPage.field.wait().safeTap()
        SearchPage.field.typeText(text)
        return self
    }

    @discardableResult
    func tapOnSearchResult(at index: Int = 0) -> Self {
        SearchPage.results.waitCount(index + 1).element(boundBy: index).waitForHitPoint().safeTap()
        return self
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertSearchResultsCount(_ expectedCount: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let actualCount = SearchPage.results.waitCount(expectedCount, exact: true).count
        XCTAssertEqual(expectedCount, actualCount, file: file, line: line)
        return self
    }

    @discardableResult
    func assertChannelInSearchResults(_ name: String, at index: Int = 0, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let result = SearchPage.results.waitCount(index + 1).element(boundBy: index)
        let actualName = SearchPage.channelName(in: result).wait().waitForText(name).text
        XCTAssertEqual(name, actualName, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageInSearchResults(_ text: String, at index: Int = 0, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let result = SearchPage.results.waitCount(index + 1).element(boundBy: index)
        let actualText = SearchPage.message(in: result).wait().waitForText(text, mustBeEqual: false).text
        XCTAssertTrue(actualText.contains(text), "'\(actualText)' does not contain '\(text)'", file: file, line: line)
        return self
    }
}
