//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest

class StressTestCase: XCTestCase {
    override func invokeTest() {
        if TestRunnerEnvironment.isStressTest {
            // Invoke the test 1k times
            for _ in 0 ... 1000 {
                autoreleasepool {
                    super.invokeTest()
                }
            }
        } else {
            super.invokeTest()
        }
    }
}
