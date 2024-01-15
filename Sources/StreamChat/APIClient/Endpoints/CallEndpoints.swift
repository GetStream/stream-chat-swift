//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    static func createCall(cid: ChannelId, callId: String, type: String) -> Endpoint<CreateCallPayload> {
        .init(
            path: .createCall(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: CallRequestBody(id: callId, type: type)
        )
    }
}
