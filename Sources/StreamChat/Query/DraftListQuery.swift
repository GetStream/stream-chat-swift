//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query used to fetch the drafts of the current user.
public struct DraftListQuery: Encodable {
    /// The pagination information to query the votes.
    public var pagination: Pagination
    /// The sorting parameter. By default drafts are sorted by newest first.
    public var sorting: [Sorting<DraftListSortingKey>]

    public init(
        pagination: Pagination = .init(pageSize: 25, offset: 0),
        sorting: [Sorting<DraftListSortingKey>] = [.init(key: .createdAt, isAscending: false)]
    ) {
        self.pagination = pagination
        self.sorting = sorting
    }

    enum CodingKeys: CodingKey {
        case pagination
        case sort
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !sorting.isEmpty {
            try container.encode(sorting, forKey: .sort)
        }
        try pagination.encode(to: encoder)
    }
}

/// The type describing a value that can be used as a sorting when paginating all the drafts of the current user.
public struct DraftListSortingKey: RawRepresentable, Hashable, SortingKey {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The supported sorting keys.
public extension DraftListSortingKey {
    /// Sorts drafts by `created_at` field.
    static let createdAt = Self(rawValue: MessagePayloadsCodingKeys.createdAt.rawValue)
}

extension Sorting where Key == DraftListSortingKey {
    func sortDescriptor() -> NSSortDescriptor? {
        switch key {
        case .createdAt:
            return .init(keyPath: \MessageDTO.createdAt, ascending: isAscending)
        default:
            return nil
        }
    }
}
