//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Int {
    /// A default channels page size.
    static let channelsPageSize = 20
    /// A default messages page size.
    static let messagesPageSize = 25
    /// A default users page size.
    static let usersPageSize = 30
    /// A default channel members page size.
    static let channelMembersPageSize = 30
    /// A default channel watchers page size.
    static let channelWatchersPageSize = 30
}

/// Basic pagination with `pageSize` and `offset`.
/// Used everywhere except `ChannelQuery`. (See `MessagesPagination`)
public struct Pagination: Encodable, Equatable {
    /// A page size.
    public let pageSize: Int
    /// An offset.
    public let offset: Int
    
    public enum CodingKeys: String, CodingKey {
        case pageSize = "limit"
        case offset
    }
    
    public init(pageSize: Int, offset: Int = 0) {
        self.pageSize = pageSize
        self.offset = offset
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pageSize, forKey: .pageSize)
        if offset != 0 {
            try container.encode(offset, forKey: .offset)
        }
    }
}

public struct MessagesPagination: Encodable, Equatable {
    /// A page size
    let pageSize: Int?
    /// Parameter for pagination.
    let parameter: PaginationParameter?
    
    /// Failable initializer for attempts of creating invalid pagination.
    init?(pageSize: Int? = nil, parameter: PaginationParameter? = nil) {
        guard pageSize != nil, parameter != nil else { return nil }
        self.pageSize = pageSize
        self.parameter = parameter
    }
    
    /// Initializer with required page size.
    init(pageSize: Int, parameter: PaginationParameter? = nil) {
        self.pageSize = pageSize
        self.parameter = parameter
    }
    
    public enum CodingKeys: String, CodingKey {
        case pageSize = "limit"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pageSize, forKey: .pageSize)
        try parameter.map { try $0.encode(to: encoder) }
    }
}

/// Pagination parameters
public enum PaginationParameter: Encodable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case greaterThan = "id_gt"
        case greaterThanOrEqual = "id_gte"
        case lessThan = "id_lt"
        case lessThanOrEqual = "id_lte"
    }
    
    /// Filter on ids greater than the given value.
    case greaterThan(_ id: String)
    
    /// Filter on ids greater than or equal to the given value.
    case greaterThanOrEqual(_ id: String)
    
    /// Filter on ids smaller than the given value.
    case lessThan(_ id: String)
    
    /// Filter on ids smaller than or equal to the given value.
    case lessThanOrEqual(_ id: String)

    /// Parameters for a request.
    var parameters: [String: Any] {
        switch self {
        case let .greaterThan(id):
            return ["id_gt": id]
        case let .greaterThanOrEqual(id):
            return ["id_gte": id]
        case let .lessThan(id):
            return ["id_lt": id]
        case let .lessThanOrEqual(id):
            return ["id_lte": id]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case let .greaterThan(id):
            try container.encode(id, forKey: .greaterThan)
        case let .greaterThanOrEqual(id):
            try container.encode(id, forKey: .greaterThanOrEqual)
        case let .lessThan(id):
            try container.encode(id, forKey: .lessThan)
        case let .lessThanOrEqual(id):
            try container.encode(id, forKey: .lessThanOrEqual)
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.greaterThan(value1), .greaterThan(value2)),
             let (.greaterThanOrEqual(value1), .greaterThanOrEqual(value2)),
             let (.lessThan(value1), .lessThan(value2)),
             let (.lessThanOrEqual(value1), .lessThanOrEqual(value2)):
            return value1 == value2
        default:
            return false
        }
    }
}
