//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public enum TestRunnerEnvironment {
    /// `true` if the tests are currently running on the CI. We get this information by checking for the custom `CI` environment
    /// variable passed in to the process.
    public static var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] == "TRUE"
    }
    
    /// Number of stress test invocations
    public static var testInvocations: Int {
        ProcessInfo.processInfo.environment["TEST_INVOCATIONS"].flatMap(Int.init) ?? 1
    }
    
    /// `true` if we invoke stress tests more than a single time
    public static var isStressTest: Bool { testInvocations > 1 }
}
