//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestHelpers
import XCTest

final class CooldownTracker_Tests: XCTestCase {
    var sut: CooldownTracker!
    
    func test_start_thenStartTimer() {
        // GIVEN
        let cooldownTime = 3
        let timer = ScheduledStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.start(with: cooldownTime)
        
        // THEN
        XCTAssertEqual(timer.startCallCount, 1)
    }
    
    func test_start_whenCooldownIsZero_thenDontStartTimer() {
        // GIVEN
        let cooldownTime = 0
        let timer = ScheduledStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.start(with: cooldownTime)
        
        // THEN
        XCTAssertEqual(timer.startCallCount, 0)
    }
    
    func test_start_whenDurationChanges_thenOnChangeIsCalled() {
        // GIVEN
        let cooldownTime = 3
        let timer = ScheduledStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        let exp = expectation(description: "on change is called")
        var currentTimeChanged = 0
        sut.onChange = { currentTime in
            currentTimeChanged = currentTime
            exp.fulfill()
        }
        
        // WHEN
        sut.start(with: cooldownTime)
        timer.onChange?()
        
        // THEN
        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(cooldownTime, currentTimeChanged)
    }
    
    func test_start_whenDurationChanges_andDurationIsNotZero_thenDecreaseDuration_andTimerIsNotStopped() {
        // GIVEN
        let cooldownTime = 3
        let timer = ScheduledStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        let exp = expectation(description: "should decrease duration")
        exp.expectedFulfillmentCount = 2
        var durationChanged: Int = 3
        sut.onChange = { duration in
            durationChanged = duration
            exp.fulfill()
        }
        
        // WHEN
        sut.start(with: cooldownTime)
        timer.onChange?()
        timer.onChange?()
        
        // THEN
        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(durationChanged, 2)
        XCTAssertEqual(timer.stopCallCount, 0)
    }
    
    func test_start_whenDurationChanges_andDurationIsZero_thenTimerIsStopped() {
        // GIVEN
        let cooldownTime = 1
        let timer = ScheduledStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        let exp = expectation(description: "should decrease duration")
        exp.expectedFulfillmentCount = 2
        var durationChanged: Int = 1
        sut.onChange = { duration in
            durationChanged = duration
            exp.fulfill()
        }
        
        // WHEN
        sut.start(with: cooldownTime)
        timer.onChange?()
        timer.onChange?()
        
        // THEN
        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(durationChanged, 0)
        XCTAssertEqual(timer.stopCallCount, 1)
    }
    
    func test_stop_whenTimerIsRunning_thenTimerIsNotStopped() {
        // GIVEN
        let timer = ScheduledStreamTimer_Mock()
        timer.isRunning = true
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.stop()
        
        // THEN
        XCTAssertEqual(timer.stopCallCount, 1)
    }
    
    func test_deinit_whenTimerIsRunning_thenStopTimer() {
        // GIVEN
        let cooldownTime = 3
        let timer = ScheduledStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        timer.isRunning = true
        
        // WHEN
        sut.start(with: cooldownTime)
        sut = nil
        
        // THEN
        XCTAssertEqual(timer.stopCallCount, 1)
    }
    
    func test_deinit_whenTimerIsNotRunning_thenDontStopTimer() {
        // GIVEN
        let cooldownTime = 3
        let timer = ScheduledStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.start(with: cooldownTime)
        sut = nil
        
        // THEN
        XCTAssertEqual(timer.stopCallCount, 0)
    }
}
