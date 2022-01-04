//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

/// Allows synchronously waiting for the provided value to become non-nil and returns the unwrap value.
///
/// Example usage:
/// ```
///   var someComputedValue: T? { ... }
///   let unwrapped: T = try unwrapAsync(someComputedValue)
/// ```
///
/// - Parameters:
///   - timeout: The maximum time this function waits for the value to become non-nil.
///   - valueToBeUnwrapped: The value which is periodically check for becoming non-nil.
///
/// - Throws: `WaiterError.waitingForResultTimedOut` if `valueToBeUnwrapped` doesn't become non-nil
/// within the `timeout` period.
///
/// - Returns: The unwrapped value.
func unwrapAsync<T>(
    timeout: TimeInterval = defaultTimeout,
    file: StaticString = #file,
    line: UInt = #line,
    _ valueToBeUnwrapped: @autoclosure (() -> T?)
) throws -> T {
    var value: T? { valueToBeUnwrapped() }
    AssertAsync.willBeTrue(value != nil, message: "Failed to unwrap the value within the specied timeout.", file: file, line: line)
    return value!
}
