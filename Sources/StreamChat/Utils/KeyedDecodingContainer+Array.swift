//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

private struct ElementWrapper<T: Decodable>: Decodable {
    let value: T?
    var rawJSON: [String: RawJSON]?
    var error: Error?
    init(from decoder: Decoder) throws {
        do {
            value = try T(from: decoder)
        } catch {
            value = nil
            self.error = error
            // We decode the payload as RawJSON to be able to display the payload in case of error
            rawJSON = try? [String: RawJSON](from: decoder)
        }
    }
}

extension KeyedDecodingContainer {
    func decodeArrayIgnoringFailures<T: Decodable>(_ type: [T].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [T] {
        let wrappers = try decode([ElementWrapper<T>].self, forKey: key)
        for wrapper in wrappers where wrapper.error != nil {
            let rawJSONPrettyPrinted = (try? JSONEncoder.default.encode(wrapper.rawJSON))?.debugPrettyPrintedJSON
                ?? String(describing: wrapper.rawJSON)
            var errorDescription = String(describing: wrapper.error)
            if let error = wrapper.error as? DecodingError {
                errorDescription = error.prettyPrintedDescription
            }
            log.error("Failed to decode \(T.self) in array: \(rawJSONPrettyPrinted), error: \(errorDescription)")
        }
        return wrappers.compactMap(\.value)
    }
}

private extension DecodingError {
    var prettyPrintedDescription: String {
        var errorDescription = String(describing: self)
        switch self {
        case let .typeMismatch(any, context):
            errorDescription = "typeMismatch for value \(any), path: \(context.prettyPrintedCodingPath), debugDescription: \(context.debugDescription)"
            if let underlyingError = context.underlyingError {
                errorDescription.append(", underlyingError: \(underlyingError)")
            }
        case let .valueNotFound(any, context):
            errorDescription = "valueNotFound for value \(any), path: \(context.prettyPrintedCodingPath), debugDescription: \(context.debugDescription)"
            if let underlyingError = context.underlyingError {
                errorDescription.append(", underlyingError: \(underlyingError)")
            }
        case let .keyNotFound(codingKey, context):
            errorDescription = "valueNotFound for key \(codingKey), path: \(context.prettyPrintedCodingPath), debugDescription: \(context.debugDescription)"
            if let underlyingError = context.underlyingError {
                errorDescription.append(", underlyingError: \(underlyingError)")
            }
        case let .dataCorrupted(context):
            errorDescription = "dataCorrupted, path: \(context.prettyPrintedCodingPath), debugDescription: \(context.debugDescription)"
            if let underlyingError = context.underlyingError {
                errorDescription.append(", underlyingError: \(underlyingError)")
            }
        @unknown default:
            break
        }
        return errorDescription
    }
}

private extension DecodingError.Context {
    var prettyPrintedCodingPath: String {
        var lastCodingKey: CodingKey?
        var description = "<"
        for key in codingPath {
            if let intValue = key.intValue, lastCodingKey?.intValue == nil {
                description.append("[\(intValue)]")
            } else {
                if lastCodingKey != nil {
                    description.append(".")
                }
                description.append("\(key.stringValue)")
            }
            lastCodingKey = key
        }
        description.append(">")
        return description
    }
}
