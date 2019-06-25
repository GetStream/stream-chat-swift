//
//  Filter.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 24/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public enum Filter<T: CodingKey>: Encodable {
    case key(T, Operator)
    indirect case and([Filter])
    indirect case or([Filter])
    indirect case nor([Filter])
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .key(let key, let `operator`):
            try [key.stringValue: `operator`].encode(to: encoder)
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
    enum Operator: Encodable {
        case equal(to: Encodable)
        case notEqual(to: Encodable)
        case greater(than: Encodable)
        case greaterOrEqual(than: Encodable)
        case less(than: Encodable)
        case lessOrEqual(than: Encodable)
        case `in`([Encodable])
        case notIn([Encodable])
        
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
    
    static func +(lhs: Filter, rhs: Filter) -> Filter {
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
    
    static func +=(lhs: inout Filter, rhs: Filter) {
        lhs = lhs + rhs
    }
    
    static func |(lhs: Filter, rhs: Filter) -> Filter {
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
    
    static func |=(lhs: inout Filter, rhs: Filter) {
        lhs = lhs | rhs
    }
}
