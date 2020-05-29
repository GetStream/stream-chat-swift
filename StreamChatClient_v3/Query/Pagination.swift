//
// Pagination.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias Pagination = Set<PaginationOption>

public extension Pagination {
  var limit: Int? {
    first(where: { $0.limit != nil })?.limit
  }

  var offset: Int? {
    first(where: { $0.offset != nil })?.offset
  }

  func encode(to encoder: Encoder) throws {
    try forEach { try $0.encode(to: encoder) }
  }
}

public extension KeyedEncodingContainer {
  mutating func encode(_ value: Pagination, forKey key: Self.Key) throws {
    let encoder = superEncoder(forKey: key)
    try value.forEach { try $0.encode(to: encoder) }
  }
}

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
public enum PaginationOption: Encodable, Hashable {
  /// A default channels page size.
  public static let channelsPageSize: Self = .limit(20)
  /// A default channels page sizefor the next page.
  public static let channelsNextPageSize: Self = .limit(30)
  /// A default messages page size.
  public static let messagesPageSize: Self = .limit(25)
  /// A default messages page size for the next page.
  public static let messagesNextPageSize: Self = .limit(50)

  private enum CodingKeys: String, CodingKey {
    case limit
    case offset
    case greaterThan = "id_gt"
    case greaterThanOrEqual = "id_gte"
    case lessThan = "id_lt"
    case lessThanOrEqual = "id_lte"
  }

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

  /// A limit value, if the pagination has it or nil.
  public var limit: Int? {
    if case .limit(let limit) = self {
      return limit
    }

    return nil
  }

  /// An offset value, if the pagination has it or nil.
  public var offset: Int? {
    if case .offset(let offset) = self {
      return offset
    }

    return nil
  }

  /// Parameters for a request.
  var parameters: [String: Any] {
    switch self {
    case .limit(let limit):
      return ["limit": limit]
    case .offset(let offset):
      return ["offset": offset]
    case .greaterThan(let id):
      return ["id_gt": id]
    case .greaterThanOrEqual(let id):
      return ["id_gte": id]
    case .lessThan(let id):
      return ["id_lt": id]
    case .lessThanOrEqual(let id):
      return ["id_lte": id]
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
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
    }
  }

  public static func ==(lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.limit(let value1), .limit(let value2)),
         (.offset(let value1), .offset(let value2)):
      return value1 == value2
    case (.greaterThan(let value1), .greaterThan(let value2)),
         (.greaterThanOrEqual(let value1), .greaterThanOrEqual(let value2)),
         (.lessThan(let value1), .lessThan(let value2)),
         (.lessThanOrEqual(let value1), .lessThanOrEqual(let value2)):
      return value1 == value2
    default:
      return false
    }
  }
}
