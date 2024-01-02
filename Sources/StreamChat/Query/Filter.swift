//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An enum with possible operators to use in filters.
public enum FilterOperator: String {
    /// Matches values that are equal to a specified value.
    case equal = "$eq"

    /// Matches all values that are not equal to a specified value.
    case notEqual = "$ne"

    /// Matches values that are greater than a specified value.
    case greater = "$gt"

    /// Matches values that are greater than a specified value.
    case greaterOrEqual = "$gte"

    /// Matches values that are less than a specified value.
    case less = "$lt"

    /// Matches values that are less than or equal to a specified value.
    case lessOrEqual = "$lte"

    /// Matches any of the values specified in an array.
    case `in` = "$in"

    /// Matches none of the values specified in an array.
    case notIn = "$nin"

    /// Matches values by performing text search with the specified value.
    case query = "$q"

    /// Matches values with the specified text.
    case autocomplete = "$autocomplete"

    /// Matches values that exist/don't exist based on the specified boolean value.
    case exists = "$exists"

    /// Matches all the values specified in an array.
    case and = "$and"

    /// Matches at least one of the values specified in an array.
    case or = "$or"

    /// Matches none of the values specified in an array.
    case nor = "$nor"

    /// Matches if the key array contains the given value.
    case contains = "$contains"
}

/// A phantom protocol used to limit the scope of `Filter`.
///
/// This type isn't reflected in `Filter` directly, rather it's used for providing better autocompletion and compile-time
/// validation of `Filter`.
///
public protocol FilterScope {}

/// A protocol to which all values that can be used as `Filter` values conform.
///
/// Only types representing text, numbers, booleans, dates, and other filters can be on the "right-hand" side of `Filter`.
///
public protocol FilterValue: Encodable {}

// Built-in `FilterValue` conformances for supported types

extension String: FilterValue {}
extension Int: FilterValue {}
extension Double: FilterValue {}
extension Float: FilterValue {}
extension Bool: FilterValue {}
extension Date: FilterValue {}
extension URL: FilterValue {}

extension Array: FilterValue where Element: FilterValue {}
extension Filter: FilterValue {}

extension ChannelId: FilterValue {}
extension ChannelType: FilterValue {}
extension UserRole: FilterValue {}
extension AttachmentType: FilterValue {}
extension Optional: FilterValue where Wrapped == TeamId {}

/// Filter is used to specify the details about which elements should be returned from a specific query.
///
/// Learn more about how to create simple, advanced, and custom filters in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#query-filters).
///
public struct Filter<Scope: FilterScope> {
    /// An operator used for the filter.
    public let `operator`: String

    /// The "left-hand" side of the filter. Specifies the name of the field the filter should match. Some operators like
    /// `and` or `or`, don't require the key value to be present.
    public let key: String?

    /// The "right-hand" side of the filter. Specifies the value the filter should match.
    public let value: FilterValue

    /// The mapper that will transform the input value to a value that
    /// can be compared with the DB value
    typealias ValueMapper = (Any) -> FilterValue?
    let valueMapper: ValueMapper?

    /// The keypath of the DB object that will be compared with the input value during
    /// a local filtering.
    let keyPathString: String?

    /// Whether the `keyPathString` represents an array in the DTO entities.
    let isCollectionFilter: Bool

    /// The mapper that will override the DB Predicate. This might be needed
    /// for cases where our DB value is completely different from the server value.
    typealias PredicateMapper = (FilterOperator, Any) -> NSPredicate?
    let predicateMapper: PredicateMapper?

    init(
        operator: String,
        key: String?,
        value: FilterValue,
        valueMapper: ValueMapper?,
        keyPathString: String?,
        isCollectionFilter: Bool,
        predicateMapper: PredicateMapper? = nil
    ) {
        log.assert(`operator`.hasPrefix("$"), "A filter operator must have `$` prefix.")
        self.operator = `operator`
        self.key = key
        self.value = value
        self.valueMapper = valueMapper
        self.keyPathString = keyPathString
        self.isCollectionFilter = isCollectionFilter
        self.predicateMapper = predicateMapper
    }

    /// Creates a new instance of `Filter`.
    ///
    /// Learn more about how to create simple, advanced, and custom filters in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#query-filters).
    ///
    /// - Important: Creating filters directly using the initializer is an advanced operation and should be done only in
    /// specific cases.
    ///
    /// - Parameters:
    ///   - operator: An operator which should be used for the filter. The operator string must start with `$`.
    ///   - key: The "left-hand" side of the filter. Specifies the name of the field the filter should match.
    ///   - value: The "right-hand" side of the filter. Specifies the value the filter should match.
    ///   - keyPathString: the "right-hand" of the filter when it's being executed on the local storage. It should be a valid keyPath to the related DAO object.
    ///
    public init(
        operator: String,
        key: String?,
        value: FilterValue,
        isCollectionFilter: Bool
    ) {
        self.init(
            operator: `operator`,
            key: key,
            value: value,
            valueMapper: nil,
            keyPathString: nil,
            isCollectionFilter: isCollectionFilter,
            predicateMapper: nil
        )
    }
}

/// Internal initializers used by the DSL. This doesn't have to exposed publicly because customers use the
/// built-in helpers we provide.
extension Filter {
    init<Value: FilterValue>(
        operator: FilterOperator,
        key: FilterKey<Scope, Value>,
        value: FilterValue,
        valueMapper: ValueMapper?,
        keyPathString: String?
    ) {
        self.init(
            operator: `operator`.rawValue,
            key: key.rawValue,
            value: value,
            valueMapper: valueMapper,
            keyPathString: keyPathString,
            isCollectionFilter: key.isCollectionFilter,
            predicateMapper: key.predicateMapper
        )
    }

    init(
        operator: FilterOperator,
        value: FilterValue
    ) {
        self.init(
            operator: `operator`.rawValue,
            key: nil,
            value: value,
            isCollectionFilter: false
        )
    }
}

public extension Filter {
    /// Combines the provided filters and matches the values matched by all filters.
    static func and(_ filters: [Filter]) -> Filter {
        .init(operator: .and, value: filters)
    }

    /// Combines the provided filters and matches the values matched by at least one of the filters.
    static func or(_ filters: [Filter]) -> Filter {
        .init(operator: .or, value: filters)
    }

    /// Combines the provided filters and matches the values not matched by all the filters.
    static func nor(_ filters: [Filter]) -> Filter {
        .init(operator: .nor, value: filters)
    }
}

/// A helper struct that represents a key of a filter.
///
/// It allows tagging a key with a scope and a type of the value the key is related to.
///
/// Learn more about how to create filter keys for your custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#query-filters).
///
public struct FilterKey<Scope: FilterScope, Value: FilterValue>: ExpressibleByStringLiteral, RawRepresentable {
    /// The raw value of the key. This value should match the "encodable" key for the given object.
    public let rawValue: String

    /// The keypath of the DB object that will be compared with the input value during
    /// a local filtering.
    let keyPathString: String?

    /// The mapper that will transform the input value to a value that
    /// can be compared with the DB value
    typealias ValueMapper = (Any) -> FilterValue?
    typealias TypedValueMapper = (Value) -> FilterValue?
    let valueMapper: ValueMapper?

    /// The mapper that will override the DB Predicate. This might be needed
    /// for cases where our DB value is completely different from the server value.
    typealias PredicateMapper = (FilterOperator, Any) -> NSPredicate?
    typealias TypedPredicateMapper = (FilterOperator, Value) -> NSPredicate?
    let predicateMapper: PredicateMapper?

    let isCollectionFilter: Bool

    public init(stringLiteral value: String) {
        rawValue = value
        valueMapper = nil
        keyPathString = nil
        isCollectionFilter = false
        predicateMapper = nil
    }

    public init(rawValue value: String) {
        rawValue = value
        keyPathString = nil
        valueMapper = nil
        isCollectionFilter = false
        predicateMapper = nil
    }

    init(
        rawValue value: String,
        keyPathString: String,
        valueMapper: TypedValueMapper? = nil,
        isCollectionFilter: Bool = false,
        predicateMapper: TypedPredicateMapper? = nil
    ) {
        rawValue = value
        self.keyPathString = keyPathString
        self.isCollectionFilter = isCollectionFilter
        self.predicateMapper = { op, value in
            guard let predicateMapper = predicateMapper, let castInputValue = (value as? Value) else {
                return nil
            }
            return predicateMapper(op, castInputValue)
        }

        self.valueMapper = {
            guard let valueMapper = valueMapper, let castInputValue = ($0 as? Value) else {
                return nil
            }
            return valueMapper(castInputValue)
        }
    }
}

public extension Filter {
    /// Matches values that are equal to a specified value.
    static func equal<Value: Encodable>(_ key: FilterKey<Scope, Value>, to value: Value) -> Filter {
        .init(
            operator: .equal,
            key: key,
            value: value,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches all values that are not equal to a specified value.
    static func notEqual<Value: Encodable>(_ key: FilterKey<Scope, Value>, to value: Value) -> Filter {
        .init(
            operator: .notEqual,
            key: key,
            value: value,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches values that are greater than a specified value.
    static func greater<Value: Encodable>(_ key: FilterKey<Scope, Value>, than value: Value) -> Filter {
        .init(
            operator: .greater,
            key: key,
            value: value,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches values that are greater than a specified value.
    static func greaterOrEqual<Value: Encodable>(_ key: FilterKey<Scope, Value>, than value: Value) -> Filter {
        .init(
            operator: .greaterOrEqual,
            key: key,
            value: value,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches values that are less than a specified value.
    static func less<Value: Encodable>(_ key: FilterKey<Scope, Value>, than value: Value) -> Filter {
        .init(
            operator: .less,
            key: key,
            value: value,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches values that are less than or equal to a specified value.
    static func lessOrEqual<Value: Encodable>(_ key: FilterKey<Scope, Value>, than value: Value) -> Filter {
        .init(
            operator: .lessOrEqual,
            key: key,
            value: value,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches any of the values specified in an array.
    static func `in`<Value: Encodable>(_ key: FilterKey<Scope, Value>, values: [Value]) -> Filter {
        .init(
            operator: .in,
            key: key,
            value: values,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches none of the values specified in an array.
    static func notIn<Value: Encodable>(_ key: FilterKey<Scope, Value>, values: [Value]) -> Filter {
        .init(
            operator: .notIn,
            key: key,
            value: values,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches values by performing text search with the specified value.
    static func query<Value: Encodable>(_ key: FilterKey<Scope, Value>, text: String) -> Filter {
        .init(
            operator: .query,
            key: key,
            value: text,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches values with the specified text.
    static func autocomplete<Value: Encodable>(_ key: FilterKey<Scope, Value>, text: String) -> Filter {
        .init(
            operator: .autocomplete,
            key: key,
            value: text,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches values that exist/don't exist based on the specified boolean value.
    ///
    /// - Parameter exists: `true`(default value) if the filter matches values that exist. `false` if the
    /// filter should match values that don't exist.
    ///
    static func exists<Value: Encodable>(_ key: FilterKey<Scope, Value>, exists: Bool = true) -> Filter {
        .init(
            operator: .exists,
            key: key,
            value: exists,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }

    /// Matches if the key contains the given value.
    static func contains<Value: Encodable>(_ key: FilterKey<Scope, Value>, value: String) -> Filter {
        .init(
            operator: .contains,
            key: key,
            value: value,
            valueMapper: key.valueMapper,
            keyPathString: key.keyPathString
        )
    }
}

extension Filter {
    /// Filter hash that can be used to uniquely identify a filter.
    var filterHash: String {
        String(describing: self)
    }
}

extension Filter: CustomStringConvertible {
    public var description: String {
        let key = self.key ?? "*"

        guard let `operator` = FilterOperator(rawValue: self.operator) else {
            // The operator doesn't match any of the known operators
            return "\(key) \(self.operator) \(value)"
        }

        switch `operator` {
        case .equal:
            return "\(key) == \(value)"
        case .notEqual:
            return "\(key) != \(value)"
        case .greater:
            return "\(key) > \(value)"
        case .greaterOrEqual:
            return "\(key) >= \(value)"
        case .less:
            return "\(key) < \(value)"
        case .lessOrEqual:
            return "\(key) <= \(value)"
        case .in:
            return "\(key) IN \(value)"
        case .notIn:
            return "\(key) NOT IN \(value)"
        case .query:
            return "\(key) QUERY \(value)"
        case .autocomplete:
            return "\(key) AUTOCOMPLETE \(value)"
        case .exists:
            return "\(key) EXISTS \(value)"
        case .contains:
            return "\(key) CONTAINS \(value)"
        case .and:
            let filters = value as? [Filter] ?? []
            return "(" + filters.map(\.description).joined(separator: ") AND (") + ")"
        case .or:
            let filters = value as? [Filter] ?? []
            return "(" + filters.map(\.description).joined(separator: ") OR (") + ")"
        case .nor:
            let filters = value as? [Filter] ?? []
            return "(" + filters.map(\.description).joined(separator: ") NOR (") + ")"
        }
    }
}

extension Filter: Codable {
    public func encode(to encoder: Encoder) throws {
        if self.operator.isGroupOperator {
            // Filters with group operators are encoded in the following form:
            //  { $<operator>: [ <filter 1>, <filter 2> ] }
            try [self.operator: AnyEncodable(value)].encode(to: encoder)
            return

        } else if let key = self.key {
            // Normal filters are encoded in the following form:
            //  { key: { $<operator>: <value> } }
            try [key: [self.operator: AnyEncodable(value)]].encode(to: encoder)
            return

        } else {
            throw EncodingError.invalidValue(
                self,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Filter must have the `key` value when the operator is not a group operator."
                )
            )
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ArbitraryKey.self)
        for key in container.allKeys {
            if key.stringValue.hasPrefix("$") {
                // The right side should be an array of other filters
                let filters = try container.decode([Filter].self, forKey: key)
                self.init(
                    operator: key.stringValue,
                    key: nil,
                    value: filters,
                    isCollectionFilter: false
                )
                return

            } else {
                // The right side should be FilterRightSide
                let rightSide = try container.decode(FilterRightSide.self, forKey: key)
                self.init(
                    operator: rightSide.operator,
                    key: key.stringValue,
                    value: rightSide.value,
                    isCollectionFilter: false
                )
                return
            }
        }

        throw DecodingError.dataCorruptedError(
            forKey: container.allKeys.last ?? ArbitraryKey(""),
            in: container,
            debugDescription: "Filter logic structure is incorrect"
        )
    }
}

/// An arbitrary CodingKey matching all keys. Useful when the keys are not known ahead.
private struct ArbitraryKey: CodingKey, Hashable, CustomStringConvertible {
    let stringValue: String
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.init(stringValue) }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}

extension String {
    /// Returns true if the string is one of the group `FilterOperator`s
    var isGroupOperator: Bool {
        let groupOperators: [FilterOperator] = [.and, .or, .nor]
        return groupOperators.map(\.rawValue).contains(self)
    }
}

/// A struct representing the right-hand side of a filter
///
/// Example:
/// ```
///   { "key": {"$eq": "value"} }
///            ^--------------^
///               right side
/// ```
///
private struct FilterRightSide: Decodable {
    let `operator`: String
    let value: FilterValue

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ArbitraryKey.self)
        guard container.allKeys.count == 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: container.allKeys.last ?? ArbitraryKey(""),
                in: container,
                debugDescription: "FilterRightSide keys count should be only 1"
            )
        }

        let key = container.allKeys.first!
        guard key.stringValue.hasPrefix("$") else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "FilterRightSide does not contain $ operator"
            )
        }

        self.operator = container.allKeys.first!.stringValue
        var value: FilterValue?

        if let dateValue = try? container.decode(Date.self, forKey: key) {
            value = dateValue
        } else if let stringValue = try? container.decode(String.self, forKey: key) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: key) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self, forKey: key) {
            value = boolValue
        } else if let stringArray = try? container.decode([String].self, forKey: key) {
            value = stringArray
        } else if let intArray = try? container.decode([Int].self, forKey: key) {
            value = intArray
        } else if let doubleArray = try? container.decode([Double].self, forKey: key) {
            value = doubleArray
        }

        if let value = value {
            self.value = value
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "The data can't be decoded as `FilterValue`."
            )
        }
    }
}
