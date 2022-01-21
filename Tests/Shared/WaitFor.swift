//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

enum WaiterError: Error {
    case waitingForResultTimedOut
}

/// The maximum time `waitFor` waits for the wrapped function to complete. When running stress tests, this value
/// is much higher because the system might be under very heavy load.
private let waitForTimeout: TimeInterval = TestRunnerEnvironment.isStressTest || TestRunnerEnvironment.isCI ? 10 : 1

/// Allows calling an asynchronous function in the synchronous way in tests.
///
/// Example usage:
/// ```
///   func asyncFunction(completion: (T) -> Void) { }
///   let result: T = try waitFor { asyncFunction(completion: $0) }
/// ```
///
/// - Parameters:
///   - timeout: The maximum time this function waits for `action` to complete.
///   - action: The asynchronous action this function wrapps.
///   - done: `action` is required to call this closure when finished. The value then becomes the return value of
///     the whole `waitFor` function.
///
/// - Throws: `WaiterError.waitingForResultTimedOut` if `action` doesn't call the completion closure within the `timeout` period.
///
/// - Returns: The result of `action`.
func waitFor<T>(
    timeout: TimeInterval = waitForTimeout,
    file: StaticString = #file,
    line: UInt = #line,
    _ action: (_ done: @escaping (T) -> Void) -> Void
) throws -> T {
    let expectation = XCTestExpectation(description: "Action completed")
    var result: T?
    action { resultValue in
        result = resultValue
        if Thread.isMainThread {
            expectation.fulfill()
        } else {
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }
    }
    
    let waiterResult = XCTWaiter.wait(for: [expectation], timeout: timeout)
    switch waiterResult {
    case .completed where result != nil:
        return result!
    default:
        XCTFail("Waiting for the result timed out", file: file, line: line)
        throw WaiterError.waitingForResultTimedOut
    }
}
