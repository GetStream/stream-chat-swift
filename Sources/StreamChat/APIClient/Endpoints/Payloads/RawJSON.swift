//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A `RawJSON` type. The type used for handling extra data.
/// Used to store and operate objects of unknown structure that's not possible to decode.
/// https://forums.swift.org/t/new-unevaluated-type-for-decoder-to-allow-later-re-encoding-of-data-with-unknown-structure/11117
public indirect enum RawJSON: Codable, Hashable {
    case number(Double)
    case string(String)
    case bool(Bool)
    case dictionary([String: RawJSON])
    case array([RawJSON])
    case `nil`

    static let double = number

    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()
        if let value = try? singleValueContainer.decode(Bool.self) {
            self = .bool(value)
            return
        } else if let value = try? singleValueContainer.decode(String.self) {
            self = .string(value)
            return
        } else if let value = try? singleValueContainer.decode(Double.self) {
            self = .number(value)
            return
        } else if let value = try? singleValueContainer.decode([String: RawJSON].self) {
            self = .dictionary(value)
            return
        } else if let value = try? singleValueContainer.decode([RawJSON].self) {
            self = .array(value)
            return
        } else if singleValueContainer.decodeNil() {
            self = .nil
            return
        }
        throw DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Could not find reasonable type to map to JSONValue"
        ))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .string(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case let .dictionary(value): try container.encode(value)
        case .nil: try container.encodeNil()
        }
    }
}

// MARK: Raw Values Helpers

public extension RawJSON {
    /// Extracts a number value of RawJSON.
    /// Returns nil if the value is not a number.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let price = extraData["price"]?.numberValue ?? 0
    /// ```
    var numberValue: Double? {
        guard case let .number(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts a string value of RawJSON.
    /// Returns nil if the value is not a string.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let email = extraData["email"]?.stringValue ?? ""
    /// ```
    var stringValue: String? {
        guard case let .string(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts a bool value of RawJSON.
    /// Returns nil if the value is not a bool.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let isManager = extraData["isManager"]?.boolValue ?? false
    /// ```
    var boolValue: Bool? {
        guard case let .bool(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts a dictionary value of RawJSON.
    /// Returns nil if the value is not a dictionary.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let flightPrice = extraData["flight"]?.dictionaryValue?["price"]?.numberValue ?? 0
    /// ```
    var dictionaryValue: [String: RawJSON]? {
        guard case let .dictionary(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts an array value of RawJSON.
    /// Returns nil if the value is not an array.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let flights: [RawJSON]? = extraData["flights"]?.arrayValue
    /// ```
    var arrayValue: [RawJSON]? {
        guard case let .array(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts a number array of RawJSON.
    /// Returns nil if the value is not an array of numbers.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let ages = extraData["ages"]?.numberArrayValue ?? []
    /// ```
    var numberArrayValue: [Double]? {
        guard let rawArrayValue = arrayValue else {
            return nil
        }

        return rawArrayValue.compactMap(\.numberValue)
    }

    /// Extracts a string array of RawJSON.
    /// Returns nil if the value is not an array of strings.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let names = extraData["names"]?.stringArrayValue ?? []
    /// ```
    var stringArrayValue: [String]? {
        guard let rawArrayValue = arrayValue else {
            return nil
        }

        return rawArrayValue.compactMap(\.stringValue)
    }

    /// Extracts a bool array of RawJSON.
    /// Returns nil if the value is not an array of bools.
    var boolArrayValue: [Bool]? {
        guard let rawArrayValue = arrayValue else {
            return nil
        }

        return rawArrayValue.compactMap(\.boolValue)
    }

    /// Checks if the RawJSON value is null.
    var isNil: Bool {
        switch self {
        case .nil:
            return true
        default:
            return false
        }
    }
}

// MARK: ExpressibleByLiteral

extension RawJSON: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = RawJSON

    /// RawJSON can be created by using a Dictionary Literal.
    ///
    /// Example:
    /// ```
    /// let extraData: [String: RawJSON] = [
    ///     "flight": [
    ///         "price": .number(1000),
    ///         "destination": .string("Lisbon")
    ///     ]
    /// ]
    /// ```
    public init(dictionaryLiteral elements: (String, RawJSON)...) {
        let dict: [String: RawJSON] = elements.reduce(into: [:]) { partialResult, element in
            partialResult[element.0] = element.1
        }
        self = .dictionary(dict)
    }
}

extension RawJSON: ExpressibleByArrayLiteral {
    /// RawJSON can be created by using an Array Literal.
    ///
    /// Example:
    /// ```
    /// let extraData: [String: RawJSON] = [
    ///     "names": [.string("John"), string("Doe")]
    /// ]
    /// ```
    public init(arrayLiteral elements: RawJSON...) {
        self = .array(elements)
    }
}

extension RawJSON: ExpressibleByStringLiteral {
    /// RawJSON can be created by using a String Literal.
    ///
    /// Example:
    /// ```
    /// let extraData: [String: RawJSON] = [
    ///     "names": ["John", "Doe"] // instead of [.string("John"), .string("Doe")]
    /// ]
    /// ```
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension RawJSON: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    /// RawJSON can be created by using a Float Literal.
    ///
    /// Example:
    /// ```
    /// let extraData: [String: RawJSON] = [
    ///     "distances": [3.5, 4.5] // instead of [.number(3.5), .number(3.5)]
    /// ]
    /// ```
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(value)
    }

    /// RawJSON can be created by using an Integer Literal.
    ///
    /// Example:
    /// ```
    /// let extraData: [String: RawJSON] = [
    ///     "ages": [23, 32] // instead of [.number(23.0), .number(32.0)]
    /// ]
    /// ```
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Double(value))
    }
}

extension RawJSON: ExpressibleByBooleanLiteral {
    /// RawJSON can be created by using a Bool Literal.
    ///
    /// Example:
    /// ```
    /// let extraData: [String: RawJSON] = [
    ///     "isManager": true // instead of .bool(true)
    /// ]
    /// ```
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

// MARK: Subscripts

extension RawJSON {
    /// Accesses the RawJSON as a dictionary with the given key for reading and writing.
    /// This is specially useful for accessing nested types inside the extra data dictionary.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let price = extraData["flight"]?["price"].numberValue
    /// let destination = extraData["flight"]?["destination"].stringValue
    /// ```
    subscript(key: String) -> RawJSON? {
        get {
            guard case let .dictionary(dict) = self else {
                return nil
            }

            return dict[key]
        }
        set {
            guard case var .dictionary(dict) = self else {
                return
            }

            dict[key] = newValue
            self = .dictionary(dict)
        }
    }

    /// Accesses RawJSON as an array and accesses the element at the specified position.
    /// This is specially useful for accessing arrays of nested types inside the extra data dictionary.
    ///
    /// Example:
    /// ```
    /// let extraData = message.extraData
    /// let secondFlightPrice = extraData["flights"]?[1]?["price"] ?? 0
    /// ```
    subscript(index: Int) -> RawJSON? {
        get {
            guard case let .array(array) = self else {
                return nil
            }

            return array[index]
        }
        set {
            guard case var .array(array) = self, let newValue = newValue else {
                return
            }

            array[index] = newValue
            self = .array(array)
        }
    }
}

// MARK: Deprecations

public extension RawJSON {
    @available(*, deprecated, message: "dictionaryValue property should be used instead.")
    func dictionary(with value: RawJSON?, forKey key: String) -> RawJSON? {
        guard case var .dictionary(content) = self else { return nil }
        content[key] = value
        return .dictionary(content)
    }
}
