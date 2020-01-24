//
//  Filter.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 24/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
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
    case none
    /// Filter by a given key with a given operator (see Operator).
    case key(Key, Operator)
    /// Filter with all filters (like `and`).
    indirect case and([Filter])
    /// Filter with any of filters (like `or`).
    indirect case or([Filter])
    /// Filter without any of filters (like `not or`).
    indirect case nor([Filter])
    
    public var description: String {
        switch self {
        case .none:
            return ""
        case .key(let key, let op):
            return "\(key) \(op)"
        case .and(let filters):
            return "(" + filters.map({ $0.description }).joined(separator: ") AND (") + ")"
        case .or(let filters):
            return "(" + filters.map({ $0.description }).joined(separator: ") OR (") + ")"
        case .nor(let filters):
            return "(" + filters.map({ $0.description }).joined(separator: ") NOR (") + ")"
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .none:
            break
        case .key(let key, let `operator`):
            try [key: `operator`].encode(to: encoder)
        case .and(let filters):
            try ["$and": filters].encode(to: encoder)
        case .or(let filters):
            try ["$or": filters].encode(to: encoder)
        case .nor(let filters):
            try ["$nor": filters].encode(to: encoder)
        }
    }
}

public extension Filter {
    /// An operator for the filter.
    enum Operator: Encodable, CustomStringConvertible {
        /// An equal operator.
        case equal(to: Encodable)
        /// A not equal operator.
        case notEqual(to: Encodable)
        /// A greater then operator.
        case greater(than: Encodable)
        /// A greater or equal than operator.
        case greaterOrEqual(than: Encodable)
        /// A less then operator.
        case less(than: Encodable)
        /// A less or equal than operator.
        case lessOrEqual(than: Encodable)
        /// An in list operator.
        case `in`([Encodable])
        /// A not in list operator.
        case notIn([Encodable])
        /// A query operator.
        case query(String)
        /// An autocomplete operator.
        case autocomplete(String)
        
        public var description: String {
            switch self {
            case .equal(let object):
                return "= \(object)"
            case .notEqual(let object):
                return "!= \(object)"
            case .greater(let object):
                return "> \(object)"
            case .greaterOrEqual(let object):
                return ">= \(object)"
            case .less(let object):
                return "< \(object)"
            case .lessOrEqual(let object):
                return ">= \(object)"
            case .in(let objects):
                return "IN (\(objects))"
            case .notIn(let objects):
                return "NOT IN (\(objects))"
            case .query(let object):
                return "QUERY \(object)"
            case .autocomplete(let object):
                return "CONTAINS \(object)"
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var operatorName = ""
            var operand: Encodable?
            var operands: [Encodable] = []
            
            switch self {
            case .equal(let object):
                try AnyEncodable(object).encode(to: encoder)
                return
            case .notEqual(let object):
                operatorName = "$ne"
                operand = object
            case .greater(let object):
                operatorName = "$gt"
                operand = object
            case .greaterOrEqual(let object):
                operatorName = "$gte"
                operand = object
            case .less(let object):
                operatorName = "$lt"
                operand = object
            case .lessOrEqual(let object):
                operatorName = "$lte"
                operand = object
            case .in(let objects):
                operatorName = "$in"
                operands = objects
            case .notIn(let objects):
                operatorName = "$nin"
                operands = objects
            case .query(let object):
                operatorName = "$q"
                operand = object
            case .autocomplete(let object):
                operatorName = "$autocomplete"
                operand = object
            }
            
            if !operatorName.isEmpty, let operand = operand {
                try [operatorName: AnyEncodable(operand)].encode(to: encoder)
            }
            
            if !operatorName.isEmpty, !operands.isEmpty {
                try [operatorName: operands.map({ AnyEncodable($0) })].encode(to: encoder)
            }
        }
    }
}

// MARK: - Helper Operator

public extension Filter {
    
    static func + (lhs: Filter, rhs: Filter) -> Filter {
        var newFilter: [Filter] = []
        
        if case .and(let filter) = lhs {
            newFilter.append(contentsOf: filter)
        } else {
            newFilter.append(lhs)
        }
        
        if case .and(let filter) = rhs {
            newFilter.append(contentsOf: filter)
        } else {
            newFilter.append(rhs)
        }
        
        return .and(newFilter)
    }
    
    static func += (lhs: inout Filter, rhs: Filter) {
        lhs = lhs + rhs
    }
    
    static func | (lhs: Filter, rhs: Filter) -> Filter {
        var newFilter: [Filter] = []
        
        if case .or(let filter) = lhs {
            newFilter.append(contentsOf: filter)
        } else {
            newFilter.append(lhs)
        }   
        
        if case .or(let filter) = rhs {
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

// MARK: - Key Helper

public extension Filter.Key {
    
    /// A filter with a key of the string equal to a given value.
    func equal(to value: Encodable) -> Filter {
        return .key(self, .equal(to: value))
    }
    
    /// A filter with a key of the string not equal to a given value.
    func notEqual(to value: Encodable) -> Filter {
        return .key(self, .notEqual(to: value))
    }
    
    /// A filter with a key of the string is greater than a given value.
    func greater(than value: Encodable) -> Filter {
        return .key(self, .greater(than: value))
    }
    
    /// A filter with a key of the string is greater or equal than a given value.
    func greaterOrEqual(than value: Encodable) -> Filter {
        return .key(self, .greaterOrEqual(than: value))
    }
    
    /// A filter with a key of the string is less than a given value.
    func less(than value: Encodable) -> Filter {
        return .key(self, .less(than: value))
    }
    
    /// A filter with a key of the string is less or equal than a given value.
    func lessOrEqual(than value: Encodable) -> Filter {
        return .key(self, .lessOrEqual(than: value))
    }
    
    /// A filter with a key of the string is in a given list of values.
    func `in`(_ values: [Encodable]) -> Filter {
        return .key(self, .in(values))
    }
    
    /// A filter with a key of the string is not in a given list of values.
    func notIn(_ values: [Encodable]) -> Filter {
        return .key(self, .notIn(values))
    }
    
    /// A filter with a key of the string with a query of a given value.
    func query(_ value: String) -> Filter {
        return .key(self, .query(value))
    }
    
    /// A filter with a key of the string with autocomplete of a given value.
    func autocomplete(_ value: String) -> Filter {
        return .key(self, .autocomplete(value))
    }
}

/// MARK: - Current User

extension Filter {
    public static func currentUserInMembers() -> Filter {
        return "members".in([Client.shared.user.id])
    }
}
