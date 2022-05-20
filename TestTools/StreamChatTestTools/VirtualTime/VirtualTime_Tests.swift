//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class VirtualTime_Tests: XCTestCase {
    var time: VirtualTime!
    
    override func setUp() {
        super.setUp()
        time = VirtualTime(initialTime: 0)
    }
    
    func test_timerWithZeroPeriodFires() {
        // Start non-repeating timer with 0 period and catch the moment when it fires
        var calledAtTime: TimeInterval?
        _ = time.scheduleTimer(interval: 0, repeating: false) { _ in
            calledAtTime = self.time.currentTime
        }
        
        // Run the time
        time.run()
        
        // Assert the timer is called
        XCTAssertEqual(calledAtTime, 0)
    }
    
    func test_whenRunningSameTimestampMultipleTimes_onlyNewTimersFire() {
        // Schedule 1st timer with zero interval
        var firstTimeFireCount = 0
        _ = time.scheduleTimer(interval: 0, repeating: false) { _ in
            firstTimeFireCount += 1
        }
        
        // Run the time
        time.run()
        
        // Assert the 1st timer is fired
        XCTAssertEqual(firstTimeFireCount, 1)
        
        // Schedule 2nd timer with zero interval
        var secondTimeFireCount = 0
        _ = time.scheduleTimer(interval: 0, repeating: false) { _ in
            secondTimeFireCount += 1
        }
        
        // Run the time
        time.run()

        // Assert the new timer is fired
        XCTAssertEqual(secondTimeFireCount, 1)
        // Assert the 1st timer is not fired one more time
        XCTAssertEqual(firstTimeFireCount, 1)
    }
    
    func test_simpleTimer() {
        // Setup
        var calledAtTime: TimeInterval?
        _ = time.scheduleTimer(interval: 50, repeating: false) { _ in
            calledAtTime = self.time.currentTime
        }
        
        // Action
        time.run()
        
        // Assert
        XCTAssertEqual(calledAtTime, 50)
    }
    
    func test_disabledSimpleTimer() {
        // Setup
        var calledAtTime: VirtualTime.Seconds?
        let timer = time.scheduleTimer(interval: 50, repeating: false) { _ in
            calledAtTime = self.time.currentTime
        }
        
        timer.suspend()
        
        // Action
        time.run()
        
        // Assert
        XCTAssertNil(calledAtTime)
    }
    
    func test_addingTimer_whenVirtualTimeIsRunning() {
        // Setup the first timer
        _ = time.scheduleTimer(interval: 50, repeating: false) { _ in }
        
        // This executes the first timer synchronously and pauses the time
        time.run()
        
        // Setting up the second timer should resume the time
        var secondTimerCallbackTime: VirtualTime.Seconds?
        _ = time.scheduleTimer(interval: 50, repeating: false) { _ in
            secondTimerCallbackTime = self.time.currentTime
        }
        
        XCTAssertEqual(secondTimerCallbackTime, 50 + 50)
    }
    
    func test_repeatingTimer() {
        // Setup
        var calledCounter = 0
        _ = time.scheduleTimer(interval: 5, repeating: true) { _ in
            calledCounter += 1
        }
        
        // Action
        time.run(numberOfSeconds: 51)
        
        // Assert
        XCTAssertEqual(time.currentTime, 51)
        XCTAssertEqual(calledCounter, 10)
    }
    
    func test_repeatingTimer_stopsWhenCancelled() {
        // Setup
        var calledCounter = 0
        _ = time.scheduleTimer(interval: 5, repeating: true) { timer in
            calledCounter += 1
            if calledCounter == 5 {
                timer.suspend()
            }
        }
        
        // Action
        time.run()
        
        // Assert
        XCTAssertEqual(calledCounter, 5)
    }
    
    func test_nestedTimers() {
        // Setup
        var calledAtTime: VirtualTime.Seconds?
        _ = time.scheduleTimer(interval: 10, repeating: false) { _ in
            _ = self.time.scheduleTimer(interval: 10, repeating: false) { _ in
                _ = self.time.scheduleTimer(interval: 10, repeating: false) { _ in
                    calledAtTime = self.time.currentTime
                }
            }
        }
        
        // Action
        time.run()
        
        // Assert
        XCTAssertEqual(calledAtTime, 30)
    }
}
