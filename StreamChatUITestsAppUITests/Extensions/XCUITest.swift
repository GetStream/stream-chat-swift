//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

// MARK: XCUIElement

extension XCUIElement {

    static var waitTimeout: Double { 5.0 }

    var centralCoordinates: CGPoint {
        CGPoint(x: frame.midX, y: frame.midY)
    }

    var height: Double {
        Double(frame.size.height)
    }

    var width: Double {
        Double(frame.size.width)
    }

    var hasKeyboardFocus: Bool {
        (value(forKey: "hasKeyboardFocus") as? Bool) ?? false
    }

    var text: String {
        var labelText = label as String
        labelText = label.contains("AX error") ? "" : labelText
        let valueText = value as? String
        let text = labelText.isEmpty ? valueText : labelText
        return text ?? ""
    }

    func clearAndEnterText(text: String) {
        clear()
        typeText(text)
    }

    func dragAndDrop(dropElement: XCUIElement, duration: Double = 2) {
        press(forDuration: duration, thenDragTo: dropElement)
    }

    func safeTap() {
        if !isHittable {
            let coordinate: XCUICoordinate =
                coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
            coordinate.tap()
        } else { tap() }
    }

    @discardableResult
    func waitForLoss(timeout: Double) -> Bool {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        var elementPresent = exists
        while elementPresent && endTime > Date().timeIntervalSince1970 * 1000 {
            elementPresent = exists
        }
        return !elementPresent
    }

    func waitForText(_ expectedText: String, timeout: Double) -> Bool {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        var elementPresent = exists
        var textPresent = false
        while !textPresent && elementPresent && endTime > Date().timeIntervalSince1970 * 1000 {
            elementPresent = exists
            textPresent = (text == expectedText)
        }
        return textPresent
    }

    func clear() {
        guard let oldValue = value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        tapIfExists()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldValue.count)
        typeText(deleteString)
    }

    func tapIfExists() {
        if wait(timeout: 1.0) {
            tap()
        }
    }
    
    @discardableResult
    func obtainKeyboardFocus() -> Self {
        let keyboard = XCUIApplication().keyboards.element
        wait()

        if hasKeyboardFocus == false {
            tap()
        }

        if keyboard.exists == false {
            keyboard.wait()
        }
        
        return self
    }

    @discardableResult
    func wait(timeout: Double = XCUIElement.waitTimeout) -> Bool {
        waitForExistence(timeout: timeout)
    }

    func tapFrameCenter() {
        let frameCenterCoordinate = frameCenter()
        frameCenterCoordinate.tap()
    }

    private func frameCenter() -> XCUICoordinate {
        let centerX = frame.midX
        let centerY = frame.midY

        let normalizedCoordinate = XCUIApplication().coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let frameCenterCoordinate = normalizedCoordinate.withOffset(CGVector(dx: centerX, dy: centerY))

        return frameCenterCoordinate
    }
}

// MARK: XCUIElementQuery

extension XCUIElementQuery {

    @discardableResult
    func waitCount(_ expectedCount: Int, timeout: Double) -> Int {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        var actualCount = count
        while actualCount < expectedCount && endTime > Date().timeIntervalSince1970 * 1000 {
            actualCount = count
        }
        return actualCount
    }

    var lastMatch: XCUIElement? {
        allElementsBoundByIndex.last
    }
}

// MARK: XCUIApplication
extension XCUIApplication {
    
    func setLaunchArguments(_ args: LaunchArgument...) {
        launchArguments.append(contentsOf: args.map { $0.rawValue })
    }

    func setEnvironmentVariables(_ envVars: [EnvironmentVariable: String]) {
        envVars.forEach { envVar in
            launchEnvironment[envVar.key.rawValue] = envVar.value
        }
    }

    func saveToBuffer(text: String) {
        UIPasteboard.general.string = text
    }

    func tap(x: CGFloat, y: CGFloat) {
        let normalized = coordinate(
            withNormalizedOffset: CGVector(dx: 0, dy: 0)
        )
        let coordinate = normalized.withOffset(CGVector(dx: x, dy: y))
        coordinate.tap()
    }

    func doubleTap(x: CGFloat, y: CGFloat) {
        let normalized = coordinate(
            withNormalizedOffset: CGVector(dx: 0, dy: 0)
        )
        let coordinate = normalized.withOffset(CGVector(dx: x, dy: y))
        coordinate.doubleTap()
    }

    func waitForChangingState(from previousState: State, timeout: Double) -> Bool {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        var isChanged = (previousState != state)
        while !isChanged && endTime > Date().timeIntervalSince1970 * 1000 {
            isChanged = (previousState != state)
        }
        return isChanged
    }

    func waitForLosingFocus(timeout: Double) -> Bool {
        sleep(UInt32(timeout))
        return !debugDescription.contains("subtree")
    }

    func landscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func portrait() {
        XCUIDevice.shared.orientation = .portrait
    }

    func openNotificationCenter() {
        let up = coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.001))
        let down = coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.8))
        up.press(forDuration: 0.1, thenDragTo: down)
    }

    func openControlCenter() {
        let down = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.999))
        let up = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        down.press(forDuration: 0.1, thenDragTo: up)
    }

    func back() {
        navigationBars.buttons.element(boundBy: 0).tapIfExists()
    }

    func rollUp() {
        XCUIDevice.shared.press(XCUIDevice.Button.home)
    }

    func rollUp(sec: Int, withDelay: Bool = false) {
        if withDelay { sleep(1) }
        rollUp()
        sleep(UInt32(sec))
        activate()
        if withDelay { sleep(1) }
    }

    func restart() {
        terminate()
        activate()
    }

    func bundleId() -> String {
        Bundle.main.bundleIdentifier ?? ""
    }

}

extension XCTest {
    
    func step(_ name: String, step: () -> Void) {
        XCTContext.runActivity(named: name) { _ in
            step()
        }
    }

    func GIVEN(_ name: String, actionStep: () -> Void) {
        step("GIVEN \(name)", step: actionStep)
    }

    func WHEN(_ name: String, actionStep: () -> Void) {
        step("WHEN \(name)", step: actionStep)
    }

    func THEN(_ name: String, actionStep: () -> Void) {
        step("THEN \(name)", step: actionStep)
    }

    func AND(_ name: String, actionStep: () -> Void) {
        step("AND \(name)", step: actionStep)
    }

}
