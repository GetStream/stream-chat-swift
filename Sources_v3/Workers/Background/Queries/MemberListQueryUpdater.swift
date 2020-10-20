//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class MemberListQueryUpdater<ExtraData: ExtraDataTypes>: QueryUpdater<ExtraData, ChannelMemberListQuery<ExtraData.User>> {
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
            queryEndpointCreator: { query, member in
                let memberFilter: Filter<MemberListFilterScope<ExtraData.User>> = .equal(.id, to: member.id)

                let filter = try? query.filterJSONData.flatMap {
                    try JSONDecoder.default.decode(
                        Filter<MemberListFilterScope<ExtraData.User>>.self,
                        from: $0
                    )
                }
                
                return .channelMembers(
                    query: .init(
                        cid: member.cid,
                        filter: filter.flatMap { .and([$0, memberFilter]) } ?? memberFilter
                    )
                )
            }
        )
    }
}
