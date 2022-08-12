//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func getCallToken(callId: String) -> Endpoint<CallTokenPayload> {
        .init(
            path: .callToken(callId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func createCall(cid: ChannelId, id: String, type: String) -> Endpoint<CreateCallPayload> {
        .init(
            path: .createCall(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: CreateCallRequestBody(id: id, type: type)
        )
    }
}
