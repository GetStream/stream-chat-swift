//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

extension ChannelListQuery {
    public static func mock(
        filter: Filter<ChannelListFilterScope> = .equal(.hidden, to: false),
        sort: [Sorting<ChannelListSortingKey>] = [.init(key: .updatedAt, isAscending: true)],
        pagination: Pagination = .init(pageSize: 10, offset: 0),
        messagesLimit: Int = 10,
        watchOptions: QueryOptions = []
    ) -> Self {
        var query = ChannelListQuery(
            filter: filter,
            sort: sort,
            pageSize: pagination.pageSize,
            messagesLimit: messagesLimit
        )
        query.pagination = pagination
        query.options = watchOptions
        return query
    }
}
