//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChatTestHelpers
@testable import StreamChatUI
import XCTest

final class CooldownTracker_Tests: XCTestCase {
    var sut: CooldownTracker!
    
    func test_start_thenStartTimer() {
        // GIVEN
        let cooldownTime = 3
        let timer = PeriodicStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.start(with: cooldownTime)
        
        // THEN
        XCTAssertEqual(timer.numberOfTimesStarted, 1)
    }
    
    func test_start_whenCooldownIsZero_thenDontStartTimer() {
        // GIVEN
        let cooldownTime = 0
        let timer = PeriodicStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.start(with: cooldownTime)
        
        // THEN
        XCTAssertEqual(timer.numberOfTimesStarted, 0)
    }
    
    func test_start_whenDurationChanges_thenOnChangeIsCalled() {
        // GIVEN
        let cooldownTime = 3
        let timer = PeriodicStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        sut.onChange = { currentTime in
            // THEN
            XCTAssertEqual(cooldownTime, currentTime)
        }
        timer.onChange = { [weak self] in
            self?.sut.onChange?(cooldownTime)
        }
        
        // WHEN
        sut.start(with: cooldownTime)
    }
    
    func test_start_whenDurationChanges_andDurationIsNotZero_thenDecreaseDuration_andTimerIsNotStopped() {
        // GIVEN
        let cooldownTime = 3
        let timer = PeriodicStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.start(with: cooldownTime)
        
        // THEN
        XCTAssertEqual(timer.numberOftimesStopped, 0)
    }
    
    func test_stop_whenTimerIsRunning_thenTimerIsNotStopped() {
        // GIVEN
        let timer = PeriodicStreamTimer_Mock()
        timer.isRunning = true
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.stop()
        
        // THEN
        XCTAssertEqual(timer.numberOftimesStopped, 1)
    }
    
    func test_deinit_whenTimerIsRunning_thenStopTimer() {
        // GIVEN
        let cooldownTime = 3
        let timer = PeriodicStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        timer.isRunning = true
        
        // WHEN
        sut.start(with: cooldownTime)
        sut = nil
        
        // THEN
        XCTAssertEqual(timer.numberOftimesStopped, 1)
    }
    
    func test_deinit_whenTimerIsNotRunning_thenDontStopTimer() {
        // GIVEN
        let cooldownTime = 3
        let timer = PeriodicStreamTimer_Mock()
        sut = CooldownTracker(timer: timer)
        
        // WHEN
        sut.start(with: cooldownTime)
        sut = nil
        
        // THEN
        XCTAssertEqual(timer.numberOftimesStopped, 0)
    }
}
