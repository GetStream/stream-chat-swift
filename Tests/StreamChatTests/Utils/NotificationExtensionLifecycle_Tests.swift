//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class NotificationExtensionLifecycleTests: XCTestCase {
    func test_initializingWithNilIdentifier_shouldAlwaysReturnFalse() {
        let extensionLifecycle = NotificationExtensionLifecycle(appGroupIdentifier: nil)
        XCTAssertFalse(extensionLifecycle.isAppReceivingWebSocketEvents)
        extensionLifecycle.setAppState(isReceivingEvents: true)
        XCTAssertFalse(extensionLifecycle.isAppReceivingWebSocketEvents)
    }

    func test_initializingWithValidIdentifier_isAppReceivingWebSocketEvents_shouldReturnFalseAsDefaultValue() {
        let extensionLifecycle = NotificationExtensionLifecycle(appGroupIdentifier: UUID().uuidString)
        XCTAssertFalse(extensionLifecycle.isAppReceivingWebSocketEvents)
    }

    func test_initializingWithValidIdentifier_isAppReceivingWebSocketEvents_settingStateToReceivingEvents_shouldProperlyReflectItsValue() {
        let extensionLifecycle = NotificationExtensionLifecycle(appGroupIdentifier: UUID().uuidString)
        extensionLifecycle.setAppState(isReceivingEvents: true)
        XCTAssertTrue(extensionLifecycle.isAppReceivingWebSocketEvents)
    }

    func test_initializingWithValidIdentifier_isAppReceivingWebSocketEvents_settingStateToNotReceivingEvents_shouldProperlyReflectItsValue() {
        let extensionLifecycle = NotificationExtensionLifecycle(appGroupIdentifier: UUID().uuidString)
        extensionLifecycle.setAppState(isReceivingEvents: true)
        XCTAssertTrue(extensionLifecycle.isAppReceivingWebSocketEvents)
        extensionLifecycle.setAppState(isReceivingEvents: false)
        XCTAssertFalse(extensionLifecycle.isAppReceivingWebSocketEvents)
    }
}
