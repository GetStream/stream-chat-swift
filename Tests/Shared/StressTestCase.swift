//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import XCTest

class StressTestCase: XCTestCase {
    override func invokeTest() {
        if TestRunnerEnvironment.isStressTest {
            // Invoke the test 100 times
            for _ in 0...100 {
                autoreleasepool {
                    super.invokeTest()
                }
            }
        } else {
            super.invokeTest()
        }
    }
}
