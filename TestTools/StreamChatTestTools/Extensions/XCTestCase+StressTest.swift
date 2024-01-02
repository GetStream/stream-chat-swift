//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

/// Base class for stress tests
///
/// - runs 100 times if `TestRunnerEnvironment.isStressTest`
/// - by default ends test when test failure occurs
open class StressTestCase: XCTestCase {
    override open func setUp() {
        super.setUp()
        
        continueAfterFailure = false
    }
    
    override open func invokeTest() {
        for _ in 0..<TestRunnerEnvironment.testInvocations {
            autoreleasepool {
                super.invokeTest()
            }
        }
    }
}
