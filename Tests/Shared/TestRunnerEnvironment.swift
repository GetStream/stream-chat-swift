//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct TestRunnerEnvironment {
    /// `true` if the tests are currently running on the CI. We get this information by checking for the custom `CI` environment
    /// variable passed in to the process.
    static var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] == "TRUE"
    }
    
    /// `true` if the current tests are stress test. We get this information by checking for the custom `STRESS_TESTS` environment
    /// variable passed in to the process.
    static var isStressTest: Bool {
        ProcessInfo.processInfo.environment["STRESS_TESTS"] == "TRUE"
    }
}
