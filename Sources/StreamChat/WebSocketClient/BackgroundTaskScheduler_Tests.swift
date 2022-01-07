//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

#if os(iOS)
class IOSBackgroundTaskScheduler_Tests: XCTestCase {
    func test_notifications_foreground() {
        // Arrange: Subscribe for app notifications
        let scheduler = IOSBackgroundTaskScheduler()
        var calledBackground = false
        var calledForeground = false
        scheduler.startListeningForAppStateUpdates(
            onEnteringBackground: { calledBackground = true },
            onEnteringForeground: { calledForeground = true }
        )

        // Act: Send notification
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Assert: Only intended closure is called
        XCTAssertTrue(calledForeground)
        XCTAssertFalse(calledBackground)
    }

    func test_notifications_background() {
        // Arrange: Subscribe for app notifications
        let scheduler = IOSBackgroundTaskScheduler()
        var calledBackground = false
        var calledForeground = false
        scheduler.startListeningForAppStateUpdates(
            onEnteringBackground: { calledBackground = true },
            onEnteringForeground: { calledForeground = true }
        )

        // Act: Send notification
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Assert: Only intended closure is called
        XCTAssertFalse(calledForeground)
        XCTAssertTrue(calledBackground)
    }
}
#endif
