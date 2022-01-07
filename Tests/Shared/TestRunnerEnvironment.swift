//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

enum TestRunnerEnvironment {
    /// `true` if the tests are currently running on the CI. We get this information by checking for the custom `CI` environment
    /// variable passed in to the process.
    static var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] == "TRUE"
    }
    
    /// Number of stress test invocations
    static var testInvocations: Int {
        ProcessInfo.processInfo.environment["TEST_INVOCATIONS"].flatMap(Int.init) ?? 1
    }
    
    /// `true` if we invoke stress tests more than a single time
    static var isStressTest: Bool { testInvocations > 1 }
}
