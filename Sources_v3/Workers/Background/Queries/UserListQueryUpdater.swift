//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class UserListQueryUpdater<ExtraData: ExtraDataTypes>: QueryUpdater<ExtraData, UserListQuery<ExtraData.User>> {
    init(
        database: DatabaseContainer,
        webSocketClient: WebSocketClient,
        apiClient: APIClient
    ) {
        super.init(
            database: database,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            itemCreator: { $0.asModel() },
            queryEndpointCreator: { query, user in
                let userFilter: Filter<UserListFilterScope<ExtraData.User>> = .equal(.id, to: user.id)

                let filter = try? JSONDecoder.default.decode(
                    Filter<UserListFilterScope<ExtraData.User>>.self,
                    from: query.filterJSONData
                )
                
                return .users(
                    query: .init(
                        filter: filter.flatMap { .and([$0, userFilter]) } ?? userFilter
                    )
                )
            }
        )
    }
}
