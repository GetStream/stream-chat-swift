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
    
    // MARK: Combine operators
    
    /// Filter with all filters (like `and`).
    indirect case and([Filter])
    /// Filter with any of filters (like `or`).
    indirect case or([Filter])
    /// Filter without any of filters (like `not or`).
    indirect case nor([Filter])
    
    public var description: String {
        switch self {
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
            return "\(key) CONTAINS \(object)"
        case .and(let filters):
            return "(" + filters.map({ $0.description }).joined(separator: ") AND (") + ")"
        case .or(let filters):
            return "(" + filters.map({ $0.description }).joined(separator: ") OR (") + ")"
        case .nor(let filters):
            return "(" + filters.map({ $0.description }).joined(separator: ") NOR (") + ")"
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var keyOperand: Key = ""
        var operatorName = ""
        var operand: Encodable?
        var operands: [Encodable] = []
        
        switch self {
        case let .equal(key, object):
            try [key: AnyEncodable(object)].encode(to: encoder)
            return
        case let .notEqual(key, object):
            keyOperand = key
            operatorName = "$ne"
            operand = object
        case let .greater(key, object):
            keyOperand = key
            operatorName = "$gt"
            operand = object
        case let .greaterOrEqual(key, object):
            keyOperand = key
            operatorName = "$gte"
            operand = object
        case let .less(key, object):
            keyOperand = key
            operatorName = "$lt"
            operand = object
        case let .lessOrEqual(key, object):
            keyOperand = key
            operatorName = "$lte"
            operand = object
        case let .in(key, objects):
            keyOperand = key
            operatorName = "$in"
            operands = objects
        case let .notIn(key, objects):
            keyOperand = key
            operatorName = "$nin"
            operands = objects
        case let .query(key, object):
            keyOperand = key
            operatorName = "$q"
            operand = object
        case let .autocomplete(key, object):
            keyOperand = key
            operatorName = "$autocomplete"
            operand = object
            
        case .and(let filters):
            try ["$and": filters].encode(to: encoder)
            return
        case .or(let filters):
            try ["$or": filters].encode(to: encoder)
            return
        case .nor(let filters):
            try ["$nor": filters].encode(to: encoder)
            return
        }
        
        guard !keyOperand.isEmpty, !operatorName.isEmpty else {
            return
        }
        
        if let operand = operand {
            try [keyOperand: [operatorName: AnyEncodable(operand)]].encode(to: encoder)
        } else if !operands.isEmpty {
            try [keyOperand: [operatorName: operands.map({ AnyEncodable($0) })]].encode(to: encoder)
        }
    }
}

// MARK: - Helper Operator

public extension Filter {
    
    static func & (lhs: Filter, rhs: Filter) -> Filter {
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
    
    static func &= (lhs: inout Filter, rhs: Filter) {
        lhs = lhs & rhs
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

// MARK: - Current User

extension Filter {
    public static var currentUserInMembers: Filter {
        .in("members", [Client.shared.user.id])
    }
}
