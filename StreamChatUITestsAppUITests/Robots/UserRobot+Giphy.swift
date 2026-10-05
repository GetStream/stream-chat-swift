//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension UserRobot {
    @discardableResult
    func assertGiphyImageVisible(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = messageCell(withIndex: messageCellIndex, file: file, line: line).wait()
        XCTAssertTrue(attributes.giphyLabel(in: cell).wait().exists, "Giphy label does not exist", file: file, line: line)
        return self
    }

    @discardableResult
    func assertGiphyButtons(
        areDisplayed: Bool,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let sendButton = attributes.giphySendButton(in: cell).firstMatch
        if areDisplayed {
            XCTAssertTrue(sendButton.wait().exists, "Giphy send button is not displayed", file: file, line: line)
            XCTAssertTrue(attributes.giphyShuffleButton(in: cell).firstMatch.exists, "Giphy shuffle button is not displayed", file: file, line: line)
            XCTAssertTrue(attributes.giphyCancelButton(in: cell).firstMatch.exists, "Giphy cancel button is not displayed", file: file, line: line)
        } else {
            sendButton.waitForDisappearance()
            let visibleButtons = attributes.giphyButtons(in: cell).allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
            XCTAssertTrue(visibleButtons.isEmpty, "Giphy buttons are displayed", file: file, line: line)
        }
        return self
    }

    /// A cancelled giphy cell can linger in the accessibility tree after it disappears from the screen,
    /// so it is checked for being visible (hittable) rather than for existence.
    @discardableResult
    func assertGiphyImageIsNotDisplayed(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let giphyLabel = attributes.giphyLabel(in: cells.firstMatch)
        let endTime = Date().addingTimeInterval(XCUIElement.waitTimeout)
        while giphyLabel.exists && giphyLabel.isHittable && Date() < endTime {
            usleep(200_000)
        }
        XCTAssertFalse(giphyLabel.exists && giphyLabel.isHittable, "Giphy image is displayed", file: file, line: line)
        return self
    }
}
