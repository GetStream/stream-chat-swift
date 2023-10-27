//
//  MembersResponse.swift
//  StreamChatTestMockServer
//
//  Created by Meik Schuetz on 25/10/2023.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Swifter

public extension StreamMockServer {
    
    func configureMembersEndpoints() {
        server.register(MockEndpoint.members) { [weak self] request in
            return self?.mockMembersQuery(request)
        }
    }
    
    private func mockMembersQuery(_ request: HttpRequest) -> HttpResponse {
        guard
            let payloadQuery = request.queryParams.first(where: { $0.0 == JSONKey.payload }),
            let payload = payloadQuery.1.removingPercentEncoding?.json,
            let channelId = payload[JSONKey.id] as? String
        else {
            return .badRequest(nil)
        }

        guard let channel = findChannelById(channelId) else { return .badRequest(nil) }
        guard let members = channel[JSONKey.members] else { return .badRequest(nil) }
        return .ok(.json([JSONKey.members: members]))
    }
}
