//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

extension Robot {
    
    @discardableResult
    func assertElement(
        _ element: XCUIElement,
        state: ElementState,
        timeout: Double = XCUIElement.waitTimeout,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Self {
        element.wait(timeout: timeout)
        let expected: Bool
        let actual: Bool
        switch state {
        case .enabled(let isEnabled):
            expected = isEnabled
            actual = element.isEnabled
        case .focused(let isFocused):
            expected = isFocused
            actual = element.hasKeyboardFocus
        case .visible(let isVisible):
            expected = isVisible
            actual = element.exists
        }
        XCTAssertEqual(expected, actual, state.errorMessage, file: file, line: line)
        return self
    }

    @discardableResult
    private func assertElement(
        _ element: XCUIElement,
        isEnabled: Bool,
        isVisible: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        if isEnabled || isVisible {
            let visible = isVisible == element.isHittable
            let enabled = isEnabled == element.isEnabled
            XCTAssertTrue(visible && enabled, file: file, line: line)
        } else {
            XCTAssertFalse(element.exists, file: file, line: line)
        }
        return self
    }

    @discardableResult
    private func assertElement(
        _ element: XCUIElement,
        hasSize size: CGSize,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertEqual(element.frame.size, size)
        return self
    }
}
