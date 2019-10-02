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
/// var filter: Filter<Channel.DecodingKeys> = .key("type", .equal(to: "messaging"))
/// // Filter channels by members:
/// filter = .key("members", .in(["jon"]))
/// // Filter channels by type and members:
/// filter = .key("type", .equal(to: "messaging")) + .key("members", .in(["jon"]))
/// // Filter channels by type or members:
/// filter = .key("type", .equal(to: "messaging")) | .key("members", .in(["jon"]))
/// ```
public enum Filter: Encodable {
    /// No filter.
    case none
    /// Filter by a given key with a given operator (see Operator).
    case key(String, Operator)
    /// Filter with all filters (like `and`).
    indirect case and([Filter])
    /// Filter with any of filters (like `or`).
    indirect case or([Filter])
    /// Filter without any of filters (like `not or`).
    indirect case nor([Filter])
    
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
    enum Operator: Encodable {
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
