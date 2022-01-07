//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

/// Base class for stress tests
///
/// - runs 100 times if `TestRunnerEnvironment.isStressTest`
/// - by default ends test when test failure occurs
class StressTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
    }
    
    override func invokeTest() {
        for _ in 0..<TestRunnerEnvironment.testInvocations {
            autoreleasepool {
                super.invokeTest()
            }
        }
    }
}
