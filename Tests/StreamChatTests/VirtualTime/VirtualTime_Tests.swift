//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

class VirtualTime_Tests: XCTestCase {
    var time: VirtualTime!
    
    override func setUp() {
        super.setUp()
        time = VirtualTime(initialTime: 0)
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
