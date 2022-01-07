//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The query used to paginate pinned messages.
struct PinnedMessagesQuery: Hashable {
    /// The page size.
    let pageSize: Int
    
    /// The sorting parameter. When empty pinned messags are sorted by `pinned_at` desc
    let sorting: [Sorting<PinnedMessagesSortingKey>]
    
    /// The pagination parameter. When `nil` messages pinned most recently are returned.
    let pagination: PinnedMessagesPagination?
    
    init(
        pageSize: Int,
        sorting: [Sorting<PinnedMessagesSortingKey>] = [],
        pagination: PinnedMessagesPagination? = nil
    ) {
        self.pageSize = pageSize
        self.sorting = sorting
        self.pagination = pagination
    }
}

// MARK: - Encodable

extension PinnedMessagesQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case pageSize = "limit"
        case sort
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pageSize, forKey: .pageSize)
        
        if !sorting.isEmpty {
            try container.encode(sorting, forKey: .sort)
        }
        
        try pagination?.encode(to: encoder)
    }
}
