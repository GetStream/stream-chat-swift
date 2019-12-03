//
//  Filter.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 02/12/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

extension StreamChatCore.Filter {
    var predicate: NSPredicate? {
        switch self {
        case .none:
            return nil
        case .key(let key, let op):
            return op.predicate(with: key)
        case .and(let filters):
            return NSCompoundPredicate(andPredicateWithSubpredicates: filters.compactMap({ $0.predicate }))
        case .or(let filters):
            return NSCompoundPredicate(orPredicateWithSubpredicates: filters.compactMap({ $0.predicate }))
        case .nor(let filters):
            return NSCompoundPredicate(notPredicateWithSubpredicate:
                NSCompoundPredicate(orPredicateWithSubpredicates: filters.compactMap({ $0.predicate })))
        }
    }
}

extension StreamChatCore.Filter.Operator {
    func predicate(with key: String) -> NSPredicate? {
        let key = mapKeyWithEdgeCases(key)
        
        switch self {
        case .equal(let value):
            return predicate(key, format: "ANY \(key) == %@", value)
        case .notEqual(let value):
            return predicate(key, format: "ANY \(key) != %@", value)
        case .greater(let value):
            return predicate(key, format: "ANY \(key) > %@", value)
        case .greaterOrEqual(let value):
            return predicate(key, format: "ANY \(key) >= %@", value)
        case .less(let value):
            return predicate(key, format: "ANY \(key) < %@", value)
        case .lessOrEqual(let value):
            return predicate(key, format: "ANY \(key) <= %@", value)
        case .in(let values):
            let mappedValues = mapValuesToCVarArgs(key: key, values, emptyWarning: "Bad filter: \(key) IN")
            return mappedValues.isEmpty ? nil : NSPredicate(format: "ANY \(key) IN %@", mappedValues)
        case .notIn(let values):
            let mappedValues = mapValuesToCVarArgs(key: key, values, emptyWarning: "Bad filter: \(key) NOT IN")
            return mappedValues.isEmpty ? nil : NSPredicate(format: "NONE \(key) IN %@", mappedValues)
        case .query(let value):
            RealmDatabase.shared.logger?.log("⚠️ Skip query: \(value)")
            return nil
        case .autocomplete(let value):
            return predicate(key, format: "ANY \(key) CONTAINS %@", value)
        }
    }
    
    private func predicate(_ key: String, format: String, _ value: Encodable) -> NSPredicate? {
        if let cVarArg = mapValueToCVarArg(key: key, value, emptyWarning: format) {
            return NSPredicate(format: format, cVarArg)
        }
        
        return nil
    }
    
    private func mapValuesToCVarArgs(key: String, _ values: [Encodable], emptyWarning: String) -> [CVarArg] {
        let mappedValues = values.compactMap({ mapValueToCVarArg(key: key, $0) })
        
        if mappedValues.isEmpty {
            RealmDatabase.shared.logger?.log("⚠️ \(emptyWarning): \(values)")
        }
        
        return mappedValues
    }
    
    private func mapValueToCVarArg(key: String, _ value: Encodable, emptyWarning: String? = nil) -> CVarArg? {
        if let bool = value as? Bool {
            return bool
        }
        
        if let string = value as? String {
            return string
        }
        
        if let date = value as? Date {
            return date as NSDate
        }
        
        if let url = value as? URL {
            return url as NSURL
        }
        
        if let realmObject = value as? Object {
            return realmObject
        }
        
        if let members = value as? [StreamChatCore.Member] {
            return members.map({ $0.user.id })
        }
        
        if let user = value as? StreamChatCore.User {
            return user.id
        }
        
        if let mapping = RealmDatabase.filterValueMapping, let mappedValue = mapping(key, value) {
            return mappedValue
        }
        
        if let emptyWarning = emptyWarning {
            RealmDatabase.shared.logger?.log("⚠️ Bad value for \(emptyWarning): \(value)")
        }
        
        return nil
    }
    
    private func mapKeyWithEdgeCases(_ key: String) -> String {
        switch key {
        case "members":
            return "members.user.id"
        case "user":
            return "user.id"
        default:
            return RealmDatabase.filterKeyMapping?(key) ?? key
        }
    }
}
