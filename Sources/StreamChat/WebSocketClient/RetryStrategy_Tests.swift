//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class RetryStrategy_Tests: XCTestCase {
    var strategy: DefaultRetryStrategy!
    
    override func setUp() {
        super.setUp()
        
        strategy = DefaultRetryStrategy()
    }
    
    override func tearDown() {
        strategy = nil
        
        super.tearDown()
    }
    
    func test_consecutiveFailures_isZeroInitially() {
        XCTAssertEqual(strategy.consecutiveFailuresCount, 0)
    }
    
    func test_incrementConsecutiveFailures_makesDelaysLonger() {
        // Declare array for delays
        var delays: [TimeInterval] = []
        
        for _ in 0..<10 {
            // Ask for reconection delay
            delays.append(strategy.nextRetryDelay())
            
            // Simulate failed retry
            strategy.incrementConsecutiveFailures()
        }
        
        // Check the delays are increasing
        XCTAssert(delays.first! < delays.last!)
    }
    
    func test_incrementConsecutiveFailures_incrementsConsecutiveFailures() {
        // Cache current # of consecutive failures
        var prevValue = strategy.consecutiveFailuresCount
        
        for _ in 0..<10 {
            // Simulate failed retry
            strategy.incrementConsecutiveFailures()
            
            // Assert # of consecutive failures is incremeneted
            XCTAssertEqual(strategy.consecutiveFailuresCount, prevValue + 1)
            
            // Update # of consecutive failures
            prevValue = strategy.consecutiveFailuresCount
        }
    }
    
    func test_resetConsecutiveFailures_setsConsecutiveFailuresToZero() {
        // Simulate some # of failed retries
        for _ in 0..<Int.random(in: 10..<20) {
            strategy.incrementConsecutiveFailures()
        }
        
        // Call `resetConsecutiveFailures`
        strategy.resetConsecutiveFailures()

        // Assert # of consecutive failures is set to zero
        XCTAssertEqual(strategy.consecutiveFailuresCount, 0)
    }
    
    func test_nextRetryDelay_returnsSlightlyDifferentDelays() throws {
        // Declare a set for delays
        var delays = Set<TimeInterval>()
        
        // Denerate some delays
        for _ in 0..<10 {
            delays.insert(strategy.nextRetryDelay())
        }
        
        // Assert delays are not the same
        XCTAssertTrue(delays.count > 1)
    }
    
    func test_getDelayAfterTheFailure_returnsDelaysAndIncrementsConsecutiveFailures() {
        // Create mock strategy
        struct MockStrategy: RetryStrategy {
            let consecutiveFailuresCount: Int = 0
            let incrementConsecutiveFailuresClosure: () -> Void
            let nextRetryDelayClosure: () -> Void
            
            func resetConsecutiveFailures() {}
            
            func incrementConsecutiveFailures() {
                incrementConsecutiveFailuresClosure()
            }
            
            func nextRetryDelay() -> TimeInterval {
                nextRetryDelayClosure()
                return 0
            }
        }
        
        // Create mock strategy instance and catch `incrementConsecutiveFailures/nextRetryDelay` calls
        var incrementConsecutiveFailuresCalled = false
        var nextRetryDelayClosure = false

        var strategy = MockStrategy(
            incrementConsecutiveFailuresClosure: {
                incrementConsecutiveFailuresCalled = true
            },
            nextRetryDelayClosure: {
                // Assert failured # is incremented after the delay is computed
                XCTAssertFalse(incrementConsecutiveFailuresCalled)
                nextRetryDelayClosure = true
            }
        )
        
        // Call `getDelayAfterTheFailure`
        _ = strategy.getDelayAfterTheFailure()
        
        // Assert both methods are invoked
        XCTAssertTrue(incrementConsecutiveFailuresCalled)
        XCTAssertTrue(nextRetryDelayClosure)
    }
}
