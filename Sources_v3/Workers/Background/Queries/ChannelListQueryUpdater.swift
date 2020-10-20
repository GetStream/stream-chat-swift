//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class ChannelListQueryUpdater<ExtraData: ExtraDataTypes>: QueryUpdater<ExtraData, ChannelListQuery<ExtraData>> {
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
            queryEndpointCreator: { query, item in
                let filter = try! JSONDecoder.default.decode(
                    Filter<ChannelListFilterScope<ExtraData.Channel>>.self,
                    from: query.filterJSONData
                )
                return .channels(
                    query: .init(
                        filter: .and([filter, .equal(.cid, to: item.cid)])
                    )
                )
            }
        )
    }
}
