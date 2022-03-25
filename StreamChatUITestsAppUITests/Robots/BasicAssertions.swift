//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

extension Robot {
    
    /// Check the state of an element
    ///
    /// - Parameters:
    ///     - XCUIElement: the element that has to be verified
    ///     - ElementState: the state in which the element should be presented
    ///     - Double: the timeout that has to be used to wait for an element to appear
    /// - Returns: Self
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
    
    /// Check the availability and visibility of an element
    ///
    /// - Parameters:
    ///     - XCUIElement: the element that has to be verified
    ///     - Bool: an expected availability of the element
    ///     - Bool: an expected visibility of the element
    ///     - Double: the timeout that has to be used to wait for an element to appear
    /// - Returns: Self
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
    
    /// Check the size of an element
    ///
    /// - Parameters:
    ///     - XCUIElement: the element that has to be verified
    ///     - CGSize: an expected size of the element
    /// - Returns: Self
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
