//
//  Pagination.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// Pagination options.
///
/// For example:
/// ```
/// // Limit by 20.
/// var pagination = Pagination.limit(20)
/// // add the offset to the limit:
/// pagination += .offset(40)
///
/// // Another pagination:
/// let pagination = Pagination.limit(50) + .lessThan("some_id")
/// ```
public enum Pagination: Codable, Equatable {
    /// A default channels page size.
    public static let channelsPageSize: Pagination = .limit(20)
    /// A default channels page sizefor the next page.
    public static let channelsNextPageSize: Pagination = .limit(30)
    /// A default messages page size.
    public static let messagesPageSize: Pagination = .limit(25)
    /// A default messages page size for the next page.
    public static let messagesNextPageSize: Pagination = .limit(50)
    
    private enum CodingKeys: String, CodingKey {
        case limit
        case offset
        case greaterThan = "id_gt"
        case greaterThanOrEqual = "id_gte"
        case lessThan = "id_lt"
        case lessThanOrEqual = "id_lte"
    }
    
    /// No pagination.
    case none
    
    /// The amount of items requested from the APIs.
    case limit(_ limit: Int)
    
    /// The offset of requesting items.
    /// - Note: Using `lessThan` or `lessThanOrEqual` for pagination is preferable to using `offset`.
    case offset(_ offset: Int)
    
    /// Filter on ids greater than the given value.
    case greaterThan(_ id: String)
    
    /// Filter on ids greater than or equal to the given value.
    case greaterThanOrEqual(_ id: String)
    
    /// Filter on ids smaller than the given value.
    case lessThan(_ id: String)
    
    /// Filter on ids smaller than or equal to the given value.
    case lessThanOrEqual(_ id: String)
    
    /// Combine `Pagination`'s with each other.
    ///
    /// It's easy to use with the `+` operator. Examples:
    /// ```
    /// var pagination = .limit(10) + .greaterThan("news123")
    /// pagination += .lessThan("news987")
    /// print(pagination)
    /// // It will print:
    /// // and(pagination: .and(pagination: .limit(10), another: .greaterThan("news123")),
    /// //     another: .lessThan("news987"))
    /// ```
    indirect case and(pagination: Pagination, another: Pagination)
    
    /// A limit value, if the pagination has it or 0.
    public var limit: Int {
        if case .limit(let limit) = self {
            return limit
        }
        
        if case let .and(lhs, rhs) = self {
            let limit = lhs.limit
            
            if limit == 0 {
                return rhs.limit
            }
            
            return limit
        }
        
        return 0
    }
    
    /// An offset value, if the pagination has it or 0.
    public var offset: Int {
        if case .offset(let offset) = self {
            return offset
        }
        
        if case let .and(lhs, rhs) = self {
            let offset = lhs.offset
            
            if offset == 0 {
                return rhs.offset
            }
            
            return offset
        }
        
        return 0
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let urlString = try container.decode(String.self)
        var pagination = Pagination.none
        
        if let urlComponents = URLComponents(string: urlString), let queryItems = urlComponents.queryItems {
            queryItems.forEach { queryItem in
                if let value = queryItem.value, !value.isEmpty {
                    switch queryItem.name {
                    case "limit":
                        if let intValue = Int(value) {
                            pagination += .limit(intValue)
                        }
                    case "offset":
                        if let intValue = Int(value) {
                            pagination += .offset(intValue)
                        }
                    case "id_gt":
                        pagination += .greaterThan(value)
                    case "id_gte":
                        pagination += .greaterThanOrEqual(value)
                    case "id_lt":
                        pagination += .lessThan(value)
                    case "id_lte":
                        pagination += .lessThanOrEqual(value)
                    default:
                        break
                    }
                }
            }
        }
        
        self = pagination
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .none:
            break
        case .limit(let limit):
            try container.encode(limit, forKey: .limit)
        case .offset(let offset):
            try container.encode(offset, forKey: .offset)
        case .greaterThan(let id):
            try container.encode(id, forKey: .greaterThan)
        case .greaterThanOrEqual(let id):
            try container.encode(id, forKey: .greaterThanOrEqual)
        case .lessThan(let id):
            try container.encode(id, forKey: .lessThan)
        case .lessThanOrEqual(let id):
            try container.encode(id, forKey: .lessThanOrEqual)
        case .and(let pagination, let another):
            try pagination.encode(to: encoder)
            try another.encode(to: encoder)
        }
    }
    
    /// Parameters for a request.
    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        
        switch self {
        case .none:
            return [:]
        case .limit(let limit):
            params["limit"] = limit
        case let .offset(offset):
            params["offset"] = offset
        case let .greaterThan(id):
            params["id_gt"] = id
        case let .greaterThanOrEqual(id):
            params["id_gte"] = id
        case let .lessThan(id):
            params["id_lt"] = id
        case let .lessThanOrEqual(id):
            params["id_lte"] = id
        case let .and(pagination1, pagination2):
            params = pagination1.parameters.merged(with: pagination2.parameters)
        }
        
        return params
    }
}

// MARK: - Helper Operator

extension Pagination {
    /// An operator for combining Pagination's.
    public static func + (lhs: Pagination, rhs: Pagination) -> Pagination {
        if case .none = lhs {
            return rhs
        }
        
        if case .none = rhs {
            return lhs
        }
        
        return .and(pagination: lhs, another: rhs)
    }
    
    /// An operator for combining Pagination's.
    public static func += (lhs: inout Pagination, rhs: Pagination) {
        lhs = lhs + rhs // swiftlint:disable:this shorthand_operator
    }
}
