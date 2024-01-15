//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    /// Next page cursor.
    public let cursor: String?

    enum CodingKeys: String, CodingKey {
        case pageSize = "limit"
        case offset
        case cursor = "next"
    }

    public init(pageSize: Int, offset: Int = 0) {
        self.pageSize = pageSize
        self.offset = offset
        cursor = nil
    }

    public init(pageSize: Int, cursor: String?) {
        self.pageSize = pageSize
        self.cursor = cursor
        offset = 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pageSize, forKey: .pageSize)
        if let cursor = cursor {
            try container.encode(cursor, forKey: .cursor)
        } else if offset != 0 {
            try container.encode(offset, forKey: .offset)
        }
    }
}

public struct MessagesPagination: Encodable, Equatable {
    /// A page size
    public let pageSize: Int
    /// Parameter for pagination.
    public let parameter: PaginationParameter?

    public init(pageSize: Int, parameter: PaginationParameter? = nil) {
        self.pageSize = pageSize
        self.parameter = parameter
    }

    enum CodingKeys: String, CodingKey {
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
    enum CodingKeys: String, CodingKey {
        case greaterThan = "id_gt"
        case greaterThanOrEqual = "id_gte"
        case lessThan = "id_lt"
        case lessThanOrEqual = "id_lte"
        case around = "id_around"
    }

    /// Filter on ids greater than the given value.
    case greaterThan(_ id: String)

    /// Filter on ids greater than or equal to the given value.
    case greaterThanOrEqual(_ id: String)

    /// Filter on ids smaller than the given value.
    case lessThan(_ id: String)

    /// Filter on ids smaller than or equal to the given value.
    case lessThanOrEqual(_ id: String)

    /// Filter on messages around the given id.
    case around(_ id: String)

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
        case let .around(id):
            return ["id_around": id]
        }
    }

    /// A String value that returns the message id if the pagination will jump to a message around a given id.
    public var aroundMessageId: String? {
        switch self {
        case let .around(messageId):
            return messageId
        default:
            return nil
        }
    }

    /// A Boolean value that returns true if the pagination will jump to a message around a given id.
    public var isJumpingToMessage: Bool {
        aroundMessageId != nil
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
        case let .around(id):
            try container.encode(id, forKey: .around)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.greaterThan(value1), .greaterThan(value2)),
             let (.greaterThanOrEqual(value1), .greaterThanOrEqual(value2)),
             let (.lessThan(value1), .lessThan(value2)),
             let (.lessThanOrEqual(value1), .lessThanOrEqual(value2)),
             let (.around(value1), .around(value2)):
            return value1 == value2
        default:
            return false
        }
    }
}
