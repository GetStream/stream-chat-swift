//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

/// Helper function for creating NSError.
func error(domain: String, code: Int = -1, message: @autoclosure () -> String) -> NSError {
    NSError(domain: domain, code: code, userInfo: ["message:": message()])
}

/// Compares the given 2 JSON Serializations are equal, by creating JSON objects from Data and comparing dictionaries.
/// Recursively calls itself for nested dictionaries.
/// - Parameters:
///   - expression1: JSON object 1, as Data. From string, you can do `Data(jsonString.utf8)`
///   - expression2: JSON object 2.
func CompareJSONEqual(
    _ expression1: @autoclosure () throws -> Data,
    _ expression2: @autoclosure () throws -> [String: Any]
) throws {
    guard var json = try JSONSerialization.jsonObject(with: expression1()) as? [String: Any] else {
        throw error(domain: "CompareJSONEqual", message: "The first expression is not a valid json object!")
    }
    
    preprocessBoolValues(&json)
    
    try CompareJSONEqual(json, try expression2())
}

/// Asserts the given 2 JSON Serializations are equal, by creating JSON objects from Data and comparing dictionaries.
/// Recursively calls itself for nested dictionaries.
/// - Parameters:
///   - expression1: JSON object 1, as Data. From string, you can do `Data(jsonString.utf8)`
///   - expression2: JSON object 2.
///   - file: file the assert is being made
///   - line: line the assert is being made.
func AssertJSONEqual(
    _ expression1: @autoclosure () throws -> Data,
    _ expression2: @autoclosure () throws -> [String: Any],
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        try CompareJSONEqual(expression1(), expression2())
    } catch {
        XCTFail("Error: \(error)", file: file, line: line)
    }
}

/// Compares the given 2 JSON Serializations are equal, by creating JSON objects from Data and comparing dictionaries.
/// Recursively calls itself for nested dictionaries.
/// - Parameters:
///   - expression1: JSON object 1, as Data. From string, you can do `Data(jsonString.utf8)`
///   - expression2: JSON object 2, as Data.
func CompareJSONEqual(
    _ expression1: @autoclosure () throws -> Data,
    _ expression2: @autoclosure () throws -> Data
) throws {
    guard let json1 = try JSONSerialization.jsonObject(with: expression1()) as? [String: Any] else {
        throw error(domain: "CompareJSONEqual", message: "First expression is not a valid json object!")
    }
    guard let json2 = try JSONSerialization.jsonObject(with: expression2()) as? [String: Any] else {
        throw error(domain: "CompareJSONEqual", message: "Second expression is not a valid json object!")
    }
    
    try CompareJSONEqual(json1, json2)
}

/// Asserts the given 2 JSON Serializations are equal, by creating JSON objects from Data and comparing dictionaries.
/// Recursively calls itself for nested dictionaries.
/// - Parameters:
///   - expression1: JSON object 1, as Data. From string, you can do `Data(jsonString.utf8)`
///   - expression2: JSON object 2, as Data.
///   - file: file the assert is being made
///   - line: line the assert is being made.
func AssertJSONEqual(
    _ expression1: @autoclosure () throws -> Data,
    _ expression2: @autoclosure () throws -> Data,
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        try CompareJSONEqual(expression1(), expression2())
    } catch {
        XCTFail("Error: \(error)", file: file, line: line)
    }
}

/// Compares the given 2 JSON Serializations are equal, by creating JSON objects from Data and comparing dictionaries.
/// Recursively calls itself for nested dictionaries.
/// - Parameters:
///   - expression1: JSON object 1
///   - expression2: JSON object 2
func CompareJSONEqual(
    _ expression1: @autoclosure () throws -> [String: Any],
    _ expression2: @autoclosure () throws -> [String: Any]
) throws {
    do {
        let json1 = try expression1()
        let json2 = try expression2()
        
        guard json1.keys == json2.keys else {
            throw error(
                domain: "CompareJSONEqual",
                message: "JSON keys do not match. Expression 1 keys: \(json1.keys), Expression 2 keys: \(json2.keys)"
            )
        }
        
        try json1.forEach { key, value in
            guard let value2 = json2[key] else {
                throw error(domain: "CompareJSONEqual", message: "Expression 2 does not have value for \(key)")
            }
            if let nestedDict1 = value as? [String: Any] {
                if let nestedDict2 = value2 as? [String: Any] {
                    try CompareJSONEqual(
                        JSONSerialization.data(withJSONObject: nestedDict1),
                        JSONSerialization.data(withJSONObject: nestedDict2)
                    )
                } else {
                    throw error(
                        domain: "CompareJSONEqual",
                        message: "Nested values for key \(key) do not match. "
                            + "Expression 1 value: \(value), Expression 2 value: \(value2)"
                    )
                }
            } else if String(describing: value) != String(describing: value2) {
                // If you get a failure here because your values are arrays, you should
                // change how you encode the [String: Any] dictionary. Please see
                // `test_channelEditDetailPayload_encodedCorrectly` for more info
                throw error(
                    domain: "CompareJSONEqual",
                    message: "Values for key \(key) do not match. "
                        + "Expression 1 value: \(value), Expression 2 value: \(value2)"
                )
            }
        }
    } catch {
        throw error
    }
}

/// Asserts the given 2 JSON Serializations are equal, by creating JSON objects from Data and comparing dictionaries.
/// Recursively calls itself for nested dictionaries.
/// - Parameters:
///   - expression1: JSON object 1
///   - expression2: JSON object 2
///   - file: file the assert is being made
///   - line: line the assert is being made.
func AssertJSONEqual(
    _ expression1: @autoclosure () throws -> [String: Any],
    _ expression2: @autoclosure () throws -> [String: Any],
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        try CompareJSONEqual(expression1(), expression2())
    } catch {
        XCTFail("Error: \(error)", file: file, line: line)
    }
}

/// A helper function that converts Bool values to their string representations "true"/"false". Needed to unify the way
/// JSON is represented in Objective-C and Swift. Objective-C represents true as `1` while Swift doest it like `true`.
private func preprocessBoolValues(_ json: inout [String: Any]) {
    var newKeys: [String: Any] = [:]
    json.forEach { (key, value) in
        if let value = value as? Bool {
            newKeys[key] = value ? "true" : "false"
        }
    }
    json.merge(newKeys, uniquingKeysWith: { _, new in new })
}
