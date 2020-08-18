//
//  AssertJSONEqual.swift
//  StreamChat
//
//  Created by Bahadir Oncel on 15.05.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

/// Helper function for creating NSError.
func error(domain: String, code: Int = -1, message: @autoclosure () -> String) -> NSError {
    NSError(domain: domain, code: code, userInfo: ["message:": message()])
}

/// Asserts the given 2 JSON Serializations are equal, by creating JSON objects from Data and comparing dictionaries.
/// Recursively calls itself for nested dictionaries and generates a failure if the expressions are not equal.
/// - Parameters:
///   - expression1: JSON object 1, as Data. From string, you can do `Data(jsonString.utf8)`
///   - expression2: JSON object 2, as Data.
///   - file: file the assert is being made
///   - line: line the assert is being made.
func AssertJSONEqual(_ expression1: @autoclosure () throws -> Data,
                     _ expression2: @autoclosure () throws -> Data,
                     file: StaticString = #file,
                     line: UInt = #line) {
    
    guard let error = try CheckJSONEqual(expression1(), expression2()) else { return }
    XCTFail("Error: \(error)", file: file, line: line)
}

/// Compares the given 2 JSON Serializations are equal, by creating JSON objects from Data and comparing dictionaries.
/// Recursively calls itself for nested dictionaries and returns an error if the expressions are not equal.
/// - Parameters:
///   - expression1: JSON object 1, as Data. From string, you can do `Data(jsonString.utf8)`
///   - expression2: JSON object 2, as Data.
func CheckJSONEqual(_ expression1: @autoclosure () throws -> Data,
                    _ expression2: @autoclosure () throws -> Data) -> NSError? {
    do {
        guard let json1 = try JSONSerialization.jsonObject(with: expression1()) as? [String: Any] else {
            return error(domain: "AssertJSONEqual",
                         message: "First expression is not a valid json object!")
        }
        guard let json2 = try JSONSerialization.jsonObject(with: expression2()) as? [String: Any] else {
            return error(domain: "AssertJSONEqual",
                         message: "Second expression is not a valid json object!")
        }
        guard json1.keys == json2.keys else {
            return error(domain: "AssertJSONEqual",
                         message: "JSON keys do not match")
        }
        
        for (key, value) in json1 {
            guard let value2 = json2[key] else {
                return error(domain: "AssertJSONEqual",
                             message: "Expression 2 does not have value for \(key)")
            }
            if let nestedDict1 = value as? [String: Any] {
                if let nestedDict2 = value2 as? [String: Any] {
                    return try CheckJSONEqual(JSONSerialization.data(withJSONObject: nestedDict1),
                                              JSONSerialization.data(withJSONObject: nestedDict2))
                } else {
                    return error(domain: "AssertJSONEqual",
                                 message: "Values for key \(key) do not match")
                }
            } else if String(describing: value) != String(describing: value2) {
                return error(domain: "AssertJSONEqual",
                             message: "Values for key \(key) do not match")
            }
        }
        return nil
    } catch {
        return error as NSError
    }
}
