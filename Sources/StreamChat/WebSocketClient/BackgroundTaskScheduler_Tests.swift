//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    
    func test_whenSchedulerIsDeallocated_backgroundTaskIsEnded() {
        // Create mock scheduler type and catch `endTask` invokation
        class MockScheduler: IOSBackgroundTaskScheduler {
            let endTaskClosure: () -> Void
            
            init(endTaskClosure: @escaping () -> Void) {
                self.endTaskClosure = endTaskClosure
            }
            
            override func endTask() {
                endTaskClosure()
            }
        }
        
        // Create mock scheduler and catch `endTask`
        var endTaskCalled = false
        var scheduler: MockScheduler? = MockScheduler {
            endTaskCalled = true
        }
        
        // Assert `endTask` is not called yet
        XCTAssertFalse(endTaskCalled)
        
        // Remove all strong refs to scheduler
        scheduler = nil
        
        // Assert `endTask` is called
        XCTAssertTrue(endTaskCalled)
        
        // Simulate access to scheduler to eliminate the warning
        _ = scheduler
    }
}
#endif
