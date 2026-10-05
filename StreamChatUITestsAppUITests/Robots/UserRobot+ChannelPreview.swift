//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

extension UserRobot {
    @discardableResult
    func assertTypingIndicatorInChannelPreview(
        isShown: Bool,
        at cellIndex: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let typingText = "typing"
        let preview = ChannelListPage.Attributes.lastMessage(in: ChannelListPage.cells.element(boundBy: cellIndex))
        let endTime = Date().addingTimeInterval(XCUIElement.waitTimeout)
        var previewText = preview.text
        while previewText.contains(typingText) != isShown && Date() < endTime {
            previewText = preview.text
        }
        XCTAssertEqual(
            previewText.contains(typingText),
            isShown,
            "Unexpected channel preview: '\(previewText)'",
            file: file,
            line: line
        )
        return self
    }
}
