//
//  Await.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest

enum WaiterError: Error {
    case waitingForResultTimedOut
}

/// Allows calling an asynchronous function in the synchronous way in tests.
///
/// Example usage:
/// ```
///   func asyncFunction(completion: (T) -> Void) { }
///   let result: T = try await { asyncFunction(completion: $0) }
/// ```
///
/// - Parameters:
///   - timeout: The maximum time this function waits for `action` to complete.
///   - action: The asynchronous action this function wrapps.
///   - done: `action` is required to call this closure when finished. The value then becomes the return value of
///     the whole `await` function.
///
/// - Throws: `WaiterError.waitingForResultTimedOut` if `action` doesn't call the completion closure within the `timeout` period.
///
/// - Returns: The result of `action`.
func await<T>(timeout: TimeInterval = 0.5,
              file: StaticString = #file,
              line: UInt = #line,
              _ action: @escaping (_ done: @escaping (T) -> Void) -> Void) throws -> T {

    let expecation = XCTestExpectation(description: "Action completed")
    var result: T?
    action {
        result = $0
        expecation.fulfill()
    }

    let waiterResult = XCTWaiter.wait(for: [expecation], timeout: timeout)
    switch waiterResult {
    case .completed where result != nil:
        return result!
    default:
        XCTFail("Waiting for the result timed out", file: file, line: line)
        throw WaiterError.waitingForResultTimedOut
    }
}
