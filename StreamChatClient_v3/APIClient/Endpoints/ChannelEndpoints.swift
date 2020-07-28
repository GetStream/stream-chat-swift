//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func channels<ExtraData: ExtraDataTypes>(query: ChannelListQuery)
        -> Endpoint<ChannelListPayload<ExtraData>> {
        .init(path: "channels",
              method: .get,
              queryItems: nil,
              requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
              body: ["payload": query])
    }
    
    static func channel<ExtraData: ExtraDataTypes>(query: ChannelQuery<ExtraData>) -> Endpoint<ChannelPayload<ExtraData>> {
        .init(path: "channels/\(query.cid.type.rawValue)/\(query.cid.id)/query",
              method: .post,
              queryItems: nil,
              requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
              body: query)
    }
}
