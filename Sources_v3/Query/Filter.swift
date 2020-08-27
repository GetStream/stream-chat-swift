//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A filter.
///
/// For example:
/// ```
/// // Filter channels by type:
/// var filter = "type".equal(to: "messaging")
/// // Filter channels by members:
/// filter = "members".in(["jon"])
/// // Filter channels by type and members:
/// filter = "type".equal(to: "messaging") + "members".in(["jon"])
/// // Filter channels by type or members:
/// filter = "type".equal(to: "messaging") | "members".in(["jon"])
/// ```
public enum Filter: Encodable, CustomStringConvertible {
    public typealias Key = String
    
    /// No filter.
    /// Can be used to get all users in queryUsers
    /// Warning: Should not be used in queryChannels.
    case none
    
    // MARK: Operators
    
    /// An equal operator.
    case equal(Key, to: Encodable)
    /// A not equal operator.
    case notEqual(Key, to: Encodable)
    /// A greater then operator.
    case greater(Key, than: Encodable)
    /// A greater or equal than operator.
    case greaterOrEqual(Key, than: Encodable)
    /// A less then operator.
    case less(Key, than: Encodable)
    /// A less or equal than operator.
    case lessOrEqual(Key, than: Encodable)
    /// An in list operator.
    case `in`(Key, [Encodable])
    /// A not in list operator.
    case notIn(Key, [Encodable])
    /// A query operator.
    case query(Key, with: String)
    /// An autocomplete operator.
    case autocomplete(Key, with: String)
    /// Contains operator
    case contains(Key, Encodable)
    /// A custom operator. Please make sure to provide a valid operator.
    /// Example:  `.custom("contains", key: "teams", value: "red")`
    case custom(String, key: Key, value: Encodable)

    // MARK: Combine operators
    
    /// Filter with all filters (like `and`).
    indirect case and([Filter])
    /// Filter with any of filters (like `or`).
    indirect case or([Filter])
    /// Filter without any of filters (like `not or`).
    indirect case nor([Filter])
    
    // MARK: - Technical

    /// "Technical" enum case needed for situation when we need to keep filterHash different from the current `Filter`.
    /// Used for `NewChannelQueryUpdater`
    indirect case explicitFilterHash(Filter, String)
    
    public var description: String {
        switch self {
        case .none:
            return ""
        case let .equal(key, object):
            return "\(key) = \(object)"
        case let .notEqual(key, object):
            return "\(key) != \(object)"
        case let .greater(key, object):
            return "\(key) > \(object)"
        case let .greaterOrEqual(key, object):
            return "\(key) >= \(object)"
        case let .less(key, object):
            return "\(key) < \(object)"
        case let .lessOrEqual(key, object):
            return "\(key) >= \(object)"
        case let .in(key, objects):
            return "\(key) IN (\(objects))"
        case let .notIn(key, objects):
            return "\(key) NOT IN (\(objects))"
        case let .query(key, object):
            return "\(key) QUERY \(object)"
        case let .autocomplete(key, object):
            return "\(key) AUTOCOMPLETE \(object)"
        case let .contains(key, object):
            return "\(key) CONTAINS \(object)"
        case let .custom(`operator`, key, object):
            return "\(key) \(`operator`.uppercased()) \(object)"
        case let .and(filters):
            return "(" + filters.map(\.description).joined(separator: ") AND (") + ")"
        case let .or(filters):
            return "(" + filters.map(\.description).joined(separator: ") OR (") + ")"
        case let .nor(filters):
            return "(" + filters.map(\.description).joined(separator: ") NOR (") + ")"
        case let .explicitFilterHash(filter, _):
            return filter.description
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var keyOperand: Key = ""
        var operatorName = ""
        var operand: Encodable?
        var operands: [Encodable] = []
        
        switch self {
        case .none:
            return
        case let .equal(key, object):
            try [key: AnyEncodable(object)].encode(to: encoder)
            return
        case let .notEqual(key, object):
            keyOperand = key
            operatorName = .notEqual
            operand = object
        case let .greater(key, object):
            keyOperand = key
            operatorName = .greater
            operand = object
        case let .greaterOrEqual(key, object):
            keyOperand = key
            operatorName = .greaterOrEqual
            operand = object
        case let .less(key, object):
            keyOperand = key
            operatorName = .less
            operand = object
        case let .lessOrEqual(key, object):
            keyOperand = key
            operatorName = .lessOrEqual
            operand = object
        case let .in(key, objects):
            keyOperand = key
            operatorName = .in
            operands = objects
        case let .notIn(key, objects):
            keyOperand = key
            operatorName = .notIn
            operands = objects
        case let .query(key, object):
            keyOperand = key
            operatorName = .query
            operand = object
        case let .autocomplete(key, object):
            keyOperand = key
            operatorName = .autocomplete
            operand = object
        case let .contains(key, object):
            keyOperand = key
            operatorName = .contains
            operand = object
        case let .custom(`operator`, key, object):
            keyOperand = key
            operatorName = "$\(`operator`)"
            operand = object
            
        case let .and(filters):
            try [String.and: filters].encode(to: encoder)
            return
        case let .or(filters):
            try [String.or: filters].encode(to: encoder)
            return
        case let .nor(filters):
            try [String.nor: filters].encode(to: encoder)
            return
        case let .explicitFilterHash(filter, _):
            try filter.encode(to: encoder)
        }
        
        guard !keyOperand.isEmpty, !operatorName.isEmpty else {
            return
        }
        
        if let operand = operand {
            try [keyOperand: [operatorName: AnyEncodable(operand)]].encode(to: encoder)
        } else if !operands.isEmpty {
            try [keyOperand: [operatorName: operands.map { AnyEncodable($0) }]].encode(to: encoder)
        }
    }
}

// MARK: - Helper Operator

public extension Filter {
    static func & (lhs: Filter, rhs: Filter) -> Filter {
        var newFilter: [Filter] = []
        
        if case let .and(filter) = lhs {
            newFilter.append(contentsOf: filter)
        } else {
            newFilter.append(lhs)
        }
        
        if case let .and(filter) = rhs {
            newFilter.append(contentsOf: filter)
        } else {
            newFilter.append(rhs)
        }
        
        return .and(newFilter)
    }
    
    static func &= (lhs: inout Filter, rhs: Filter) {
        lhs = lhs & rhs
    }
    
    static func | (lhs: Filter, rhs: Filter) -> Filter {
        var newFilter: [Filter] = []
        
        if case let .or(filter) = lhs {
            newFilter.append(contentsOf: filter)
        } else {
            newFilter.append(lhs)
        }
        
        if case let .or(filter) = rhs {
            newFilter.append(contentsOf: filter)
        } else {
            newFilter.append(rhs)
        }
        
        return .or(newFilter)
    }
    
    static func |= (lhs: inout Filter, rhs: Filter) {
        lhs = lhs | rhs
    }
}

// MARK: - Hash

extension Filter {
    var filterHash: String {
        switch self {
        case let .explicitFilterHash(_, filterHash):
            return filterHash
        default:
            let hash = String(describing: self)
            if hash.isEmpty {
                return "empty"
            } else {
                return hash
            }
        }
    }
}

// Arbitrary key
private struct Keys: CodingKey, Hashable, CustomStringConvertible {
    let stringValue: String
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.init(stringValue) }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}

extension Filter: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        for key in container.allKeys {
            if key.stringValue.hasPrefix("$") {
                // and / or / nor and other operators
                let filters = try container.decode([Filter].self, forKey: key)
                switch key.stringValue {
                case .and:
                    self = .and(filters)
                    return
                case .or:
                    self = .or(filters)
                    return
                case .nor:
                    self = .nor(filters)
                    return
                default:
                    throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: ""))
                }
            } else {
                let keyValue = key.stringValue
                if let value = try? container.decode(String.self, forKey: key) {
                    // value is string -> equal
                    self = .equal(keyValue, to: value)
                    return
                }
                // Try to decode the rest as partial filter
                let rest = try container.decode(PartialFilter.self, forKey: key)
                switch rest.operator {
                case .notEqual:
                    self = .notEqual(key.stringValue, to: rest.value)
                    return
                case .greater:
                    self = .greater(key.stringValue, than: rest.value)
                    return
                case .greaterOrEqual:
                    self = .greaterOrEqual(key.stringValue, than: rest.value)
                    return
                case .less:
                    self = .less(key.stringValue, than: rest.value)
                    return
                case .lessOrEqual:
                    self = .lessOrEqual(key.stringValue, than: rest.value)
                    return
                case .in:
                    guard !rest.array.isEmpty else {
                        throw DecodingError.typeMismatch(
                            [Encodable].self,
                            .init(codingPath: decoder.codingPath, debugDescription: "")
                        )
                    }
                    self = .in(key.stringValue, rest.array)
                    return
                case .notIn:
                    guard !rest.array.isEmpty else {
                        throw DecodingError.typeMismatch(
                            [Encodable].self,
                            .init(codingPath: decoder.codingPath, debugDescription: "")
                        )
                    }
                    self = .notIn(key.stringValue, rest.array)
                    return
                case .query:
                    guard let stringValue = rest.value as? String else {
                        throw DecodingError.typeMismatch(String.self, .init(codingPath: decoder.codingPath, debugDescription: ""))
                    }
                    self = .query(key.stringValue, with: stringValue)
                    return
                case .autocomplete:
                    guard let stringValue = rest.value as? String else {
                        throw DecodingError.typeMismatch(String.self, .init(codingPath: decoder.codingPath, debugDescription: ""))
                    }
                    self = .autocomplete(key.stringValue, with: stringValue)
                    return
                case .contains:
                    self = .contains(key.stringValue, rest.value)
                    return
                default:
                    self = .custom(String(rest.operator.dropFirst()), key: key.stringValue, value: rest.value)
                    return
                }
            }
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: ""))
    }
}

struct PartialFilter: Decodable {
    let `operator`: String
    let value: Encodable
    let array: [Encodable]
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        guard container.allKeys.count == 1 else { throw ClientError() }
        let key = container.allKeys.first!
        guard key.stringValue.hasPrefix("$") else { throw ClientError() }
        self.operator = container.allKeys.first!.stringValue
        var value: Encodable?
        var array: [Encodable] = []
        
        if let stringValue = try? container.decode(String.self, forKey: key) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: key) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self, forKey: key) {
            value = boolValue
        } else if let stringArray = try? container.decode([String].self, forKey: key) {
            array = stringArray
        } else if let intArray = try? container.decode([Int].self, forKey: key) {
            array = intArray
        } else if let doubleArray = try? container.decode([Double].self, forKey: key) {
            array = doubleArray
        }
        
        if value == nil, array.isEmpty {
            throw DecodingError.typeMismatch(String.self, .init(codingPath: decoder.codingPath, debugDescription: ""))
        }
        
        self.value = value ?? ""
        self.array = array
    }
}

private extension String {
    static let and = "$and"
    static let or = "$or"
    static let nor = "$nor"
    static let notEqual = "$ne"
    static let greater = "$gt"
    static let greaterOrEqual = "$gte"
    static let less = "$lt"
    static let lessOrEqual = "$lte"
    static let `in` = "$in"
    static let notIn = "$nin"
    static let query = "$q"
    static let autocomplete = "$autocomplete"
    static let contains = "$contains"
}
