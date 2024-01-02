//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

/// Asserts diff between the expected and received values
public func XCTAssertEqual<T: Equatable>(_ expected: T,
                                         _ received: T,
                                         file: StaticString = #filePath,
                                         line: UInt = #line) {
    if TestRunnerEnvironment.isCI {
        // Use built-in `XCTAssertEqual` when running on the CI to get CI-friendly logs.
        XCTAssertEqual(received, expected, "", file: file, line: line)
    } else {
        XCTAssertTrue(
            expected == received,
            "Found difference for \n" + diff(expected, received).joined(separator: ", "),
            file: file,
            line: line
        )
    }
}

// MARK: Errors

/// Asserts when two given errors are not equal
///
/// Usage:
///       XCTAssertEqual(error, .fileSizeTooLarge(messageId: messageId))
public func XCTAssertEqual<T: Error>(_ error1: T,
                                     _ error: T,
                                     _ message: @autoclosure () -> String = "",
                                     file: StaticString = #filePath,
                                     line: UInt = #line,
                                     usesDifference: Bool = true) {
    XCTAssertEqual(error1.stringReflection,
                   error.stringReflection,
                   diffMessage(error1, received: error, message: message()),
                   file: file,
                   line: line)
}

/// Asserts when two (optional) errors are not equal.
///
/// Usage:
///       XCTAssertEqual(some?.error, .fileSizeTooLarge(messageId: messageId))
public func XCTAssertEqual<T: Error>(_ error1: T?,
                                     _ error: T,
                                     _ message: @autoclosure () -> String = "",
                                     file: StaticString = #filePath,
                                     line: UInt = #line) {
    XCTAssertEqual(error1?.stringReflection,
                   error.stringReflection,
                   diffMessage(error1, received: error, message: message()),
                   file: file,
                   line: line)
}

/// Asserts when two given errors are not equal
///
/// Usage:
///        XCTAssertEqual(error, .fileSizeTooLarge(messageId: messageId))
public func XCTAssertEqual<T: Error>(_ error1: T,
                                     _ error: T,
                                     _ message: @autoclosure () -> String = "",
                                     file: StaticString = #filePath,
                                     line: UInt = #line) where T: Equatable {
    if error == error1 {
        /// This covers the case, when `Equatable` conformance of the `Error` was overriden by the custom implementation
        XCTAssertTrue(true, message())
        return
    }

    XCTAssertEqual(error1.stringReflection,
                   error.stringReflection,
                   diffMessage(error1, received: error, message: message()),
                   file: file,
                   line: line)
}

/// Asserts when two (optional) errors are not equal.
///
/// Usage:
///       XCTAssertEqual(some?.error, .fileSizeTooLarge(messageId: messageId))
public func XCTAssertEqual<T: Error>(_ error1: T?,
                                     _ error: T,
                                     _ message: @autoclosure () -> String = "",
                                     file: StaticString = #filePath,
                                     line: UInt = #line) where T: Equatable {
    if let equalError = error1,
       equalError == error {
        /// This covers the case, when `Equatable` conformance of the `Error` was overriden by the custom implementation
        XCTAssertTrue(true, message())
        return
    }

    XCTAssertEqual(error1?.stringReflection,
                   error.stringReflection,
                   diffMessage(error1, received: error, message: message()),
                   file: file,
                   line: line)
}

// MARK: Throws

/// Asserts when given expression throws an error.
///
/// - Parameters:
///   - expression: An expression that can throw
///   - message: An description message for failure
///   - errorHandler: An error handler to access the error with concrete type
public func XCTAssertThrowsError<T, U: Error>(_ expression: @autoclosure () throws -> T,
                                              _ message: String,
                                              file: StaticString = #filePath,
                                              line: UInt = #line,
                                              _ errorHandler: (U) -> Void) {
    XCTAssertThrowsError(try expression(), message, file: file, line: line) { (error) in
        guard let typedError = error as? U else {
            XCTFail("Error: \(error) doesnt match with given error type: \(U.self)",
                    file: file,
                    line: line)
            return
        }
        errorHandler(typedError)
    }
}

/// Asserts when thrown error type doesnt match given type
public func XCTAssertThrowsError<T, U: Error>(ofType: U.Type,
                                              _ expression: @autoclosure () throws -> T,
                                              _ message: String,
                                              file: StaticString = #filePath,
                                              line: UInt = #line,
                                              _ errorHandler: (U) -> Void) {
    XCTAssertThrowsError(try expression(),
                         message,
                         file: file,
                         line: line,
                         errorHandler)
}

/// Asserts when given throwing expression doesnt throw the expected error
///
/// - Parameters:
///   - expression: throw expression
///   - error: Awaited error
///
///   Usage:
///         XCTAssertThrowsError(try PathUpdate(with: data), ParsingError.failedToParseJSON)
public func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T,
                                    _ error: Error,
                                    _ message: @autoclosure () -> String = "",
                                    file: StaticString = #filePath,
                                    line: UInt = #line) {
    XCTAssertThrowsError(try expression(), message()) { (thrownError) in
        XCTAssertEqual(thrownError,
                       error,
                       diffMessage(thrownError, received: error, message: message()),
                       file: file,
                       line: line)
    }
}

// MARK: Result

/// Asserts when given failure result `Result<Value: Equatable, ErrorType>` doesn't match the given error
///
/// - Parameters:
///   - result: Result of type `Result<Value, ErrorType>`
///   - value: Awaited success value, that is equatable
///
///   Usage:
///         XCTAssertEqual(result, success: "Success")
public func XCTAssertEqual<Value: Equatable, ErrorType>(_ result: Result<Value, ErrorType>,
                                                        success value: Value,
                                                        _ message: @autoclosure () -> String = "",
                                                        file: StaticString = #filePath,
                                                        line: UInt = #line) {
    let resultValue = XCTAssertResultSuccess(result,
                                             message(),
                                             file: file,
                                             line: line)
    XCTAssertEqual(resultValue, value, diffMessage(resultValue, received: value, message: message()), file: file, line: line)
}

/// Asserts when given failure result `Result<Value, ErrorType>` doesn't match the given error
///
/// - Parameters:
///   - result: Result of type `Result<Value, ErrorType>`
///   - error: Awaited error
///
///   Usage:
///         XCTAssertEqual(result, failure: .noMachineId)
public func XCTAssertEqual<Value, ErrorType: Error>(_ result: Result<Value, ErrorType>,
                                                    failure error: ErrorType,
                                                    _ message: @autoclosure () -> String = "",
                                                    file: StaticString = #filePath,
                                                    line: UInt = #line) {
    let errorMessage = message()
    XCTAssertResultFailure(result,
                           errorMessage,
                           file: file,
                           line: line) { failureError in
                            XCTAssertEqual(failureError,
                                           error,
                                           diffMessage(failureError, received: error, message: errorMessage),
                                           file: file,
                                           line: line)
    }
}

/// Asserts when given failure result `Result<Value, ErrorType>` doesn't match the given `equatable` error
///
/// - Parameters:
///   - result: Result of type `Result<Value, ErrorType>`
///   - error: Awaited error
///
///   Usage:
///         XCTAssertEqual(result, failure: .noMachineId)
public func XCTAssertEqual<Value, ErrorType: Error>(_ result: Result<Value, ErrorType>,
                                                    failure error: ErrorType,
                                                    _ message: @autoclosure () -> String = "",
                                                    file: StaticString = #filePath,
                                                    line: UInt = #line) where ErrorType: Equatable {
    let errorMessage = message()
    XCTAssertResultFailure(result,
                           errorMessage,
                           file: file,
                           line: line) { failureError in
                            XCTAssertEqual(failureError,
                                           error,
                                           diffMessage(failureError, received: error, message: errorMessage),
                                           file: file,
                                           line: line)
    }
}

/// Asserts when given result `Result<Value, U: Error>` is failure
@discardableResult
public func XCTAssertResultSuccess<Value, U: Error>(_ result: Result<Value, U>,
                                                    _ message: @autoclosure () -> String = "Expectation failed for result",
                                                    file: StaticString = #filePath,
                                                    line: UInt = #line) -> Value? {
    switch result {
    case .success(let value):
        return value
    case .failure:
        XCTFail(message(), file: file, line: line)
        return nil
    }
}

/// Asserts when given result `Result<Value, ErrorType>` has succeeded
///
/// - Parameters:
///   - result: Result of type `Result<Value, ErrorType>`
///   - errorHandler: This closure gives you possibility to check the error of `ErrorType` in type-safe manner
///
///   Usage:
///         XCTAssertResultFailure(result) { (error) in
///             XCTAssertEqual(error, .fileSizeTooLarge(messageId: messageId))
///         }
public func XCTAssertResultFailure<Value, ErrorType: Error>(_ result: Result<Value, ErrorType>,
                                                            _ message: @autoclosure () -> String = "",
                                                            file: StaticString = #filePath,
                                                            line: UInt = #line,
                                                            errorHandler: ((ErrorType) -> Void)? = nil) {
    XCTAssertResultFailure(result,
                           ofErrorType: ErrorType.self,
                           message(),
                           file: file,
                           line: line,
                           errorHandler: errorHandler)
}

/// Asserts when given result `Result<Value, ErrorType>` has succeeded or the result doesnt match the given `errorType`
///
/// - Parameters:
///   - result: Result of type `Result<Value, ErrorType>`
///   - errorType: Awaited error type of error propagated through result's failure case
///   - errorHandler: This closure gives you possibility to check the error of `ErrorType` in type-safe manner
///
///   Usage:
///         XCTAssertResultFailure(result) { (error) in
///             XCTAssertEqual(error, .fileSizeTooLarge(messageId: messageId))
///         }
public func XCTAssertResultFailure<Value, U: Error, ErrorType: Error>(_ result: Result<Value, U>,
                                                                      ofErrorType errorType: ErrorType.Type? = nil,
                                                                      _ message: @autoclosure () -> String = "",
                                                                      file: StaticString = #filePath,
                                                                      line: UInt = #line,
                                                                      errorHandler: ((ErrorType) -> Void)? = nil) {
    switch result {
    case .success:
        XCTFail("Result was not Failure",
                file: file,
                line: line)
    case .failure(let failureError):
        guard
            let errorType = errorType,
            let errorHandler = errorHandler else {
                return
        }

        guard let error = failureError as? ErrorType else {
            XCTFail("Result error: \(failureError) doesnt match with given error type: \(errorType)",
                    file: file,
                    line: line)
            return
        }

        errorHandler(error)
        return // then fallthrough to fulfill expectations
    }
}

/// Errors are compared through string reflection
public extension Error {
    var stringReflection: String {
        String(reflecting: self)
    }
}

// MARK: Diff message

func diffMessage<Value>(_ expected: Value,
                        received: Value,
                        message: @autoclosure () -> String = "") -> String {
    [message(),
     "Found difference for",
     diff(expected, received).joined(separator: ", ")
    ].joined(separator: "\n")
}
