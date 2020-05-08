//
//  AssertNetworkRequest.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest

/// The default timeout value use by the `Assert___Eventually` family of functions.
private let defaultTimeout: TimeInterval = 1

/// How big is the period between expression evaluations.
private let evaluationPeriod: TimeInterval = 0.001


/// Blocks the current test execution and periodically checks for the equality of the provided expressions. Fails if
/// the expression results are not equal within the `timeout` period.
///
/// - Parameters:
///   - expression1: The first expression to evaluate.
///   - expression2: The first expression to evaluate.
///   - timeout: The maximum time the function waits for the expression results to equal.
///
/// - Warning: ⚠️ Both expressions are evaluated repeatedly during the function execution. The expressions should not have
///   any side effects which can affect their results.
func AssertEqualEventually<T: Equatable>(_ expression1: @autoclosure () -> T?,
                                         _ expression2: @autoclosure () -> T?,
                                         timeout: TimeInterval = defaultTimeout,
                                         file: StaticString = #file,
                                         line: UInt = #line) {

    let startTimestamp = Date().timeIntervalSince1970

    while Date().timeIntervalSince1970 - startTimestamp < timeout {
        if expression1() == expression2() {
            return
        }
        _ = XCTWaiter.wait(for: [.init()], timeout: evaluationPeriod)
    }

    XCTAssertEqual(expression1(), expression2(), file: file, line: line)
}


/// Blocks the current test execution and periodically checks if the expression evaluates to `nil`. Fails if
/// the expression result is not `nil` within the `timeout` period.
///
/// - Parameters:
///   - expression: The expression to evaluate.
///   - timeout: The maximum time the function waits for the expression results to equal.
///
/// - Warning: ⚠️ The expression is evaluated repeatedly during the function execution. It should not have
///   any side effects which can affect its result.
func AssertNilEventually<T>(_ expression: @autoclosure () -> T?,
                            timeout: TimeInterval = defaultTimeout,
                            file: StaticString = #file,
                            line: UInt = #line) {

    let startTimestamp = Date().timeIntervalSince1970

    while Date().timeIntervalSince1970 - startTimestamp < timeout {
        if expression() == nil {
            return
        }
        _ = XCTWaiter.wait(for: [.init()], timeout: evaluationPeriod)
    }

    XCTAssertNil(expression(), file: file, line: line)
}
