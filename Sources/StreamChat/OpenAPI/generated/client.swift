//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

open class API: DefaultAPIEndpoints, @unchecked Sendable {
    internal var transport: DefaultAPITransport
    internal var middlewares: [DefaultAPIClientMiddleware]
    internal var basePath: String
    internal var jsonDecoder: JSONDecoder

    init(basePath: String, transport: DefaultAPITransport, middlewares: [DefaultAPIClientMiddleware], jsonDecoder: JSONDecoder = JSONDecoder.default) {
        self.basePath = basePath
        self.transport = transport
        self.middlewares = middlewares
        self.jsonDecoder = jsonDecoder
    }

    func send<Response: Decodable>(
        request: Request,
        deserializer: (Data) throws -> Response
    ) async throws -> Response {
        // TODO: make this a bit nicer and create an API error to make it easier to handle stuff
        func makeError(_ error: Error) -> Error {
            error
        }

        func wrappingErrors<R>(
            work: () async throws -> R,
            mapError: (Error) -> Error
        ) async throws -> R {
            do {
                return try await work()
            } catch {
                throw mapError(error)
            }
        }

        let (data, _) = try await wrappingErrors {
            var next: (Request) async throws -> (Data, URLResponse) = { _request in
                try await wrappingErrors {
                    try await self.transport.execute(request: _request)
                } mapError: { error in
                    makeError(error)
                }
            }
            for middleware in middlewares.reversed() {
                let tmp = next
                next = {
                    try await middleware.intercept(
                        $0,
                        next: tmp
                    )
                }
            }
            return try await next(request)
        } mapError: { error in
            makeError(error)
        }

        return try await wrappingErrors {
            try deserializer(data)
        } mapError: { error in
            makeError(error)
        }
    }

    func makeRequest(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String
    ) throws -> Request {
        let url = URL(string: basePath + uriPath)!
        return Request(
            url: url,
            method: .init(stringValue: httpMethod),
            queryParams: queryParams,
            headers: ["Content-Type": "application/json"]
        )
    }

    func makeRequest<T: Encodable>(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String,
        request: T
    ) throws -> Request {
        var r = try makeRequest(uriPath: uriPath, queryParams: queryParams, httpMethod: httpMethod)
        r.body = try JSONEncoder().encode(request)
        return r
    }

    private func encodeJSONToQueryItems(data: Encodable) throws -> [URLQueryItem] {
        let data = try (data as? Data) ?? JSONEncoder.stream.encode(AnyEncodable(data))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClientError.InvalidJSON("Data is not a valid JSON: \(String(data: data, encoding: .utf8) ?? "nil")")
        }

        let bodyQueryItems = json.compactMap { (key, value) -> URLQueryItem? in
            // If the `value` is a JSON, encode it like that
            if let jsonValue = value as? [String: Any] {
                do {
                    let jsonStringValue = try JSONSerialization.data(withJSONObject: jsonValue)
                    return URLQueryItem(name: key, value: String(data: jsonStringValue, encoding: .utf8))
                } catch {
                    log.error(
                        "Skipping encoding data for key:`\(key)` because it's not a valid JSON: "
                            + "\(String(data: data, encoding: .utf8) ?? "nil")", subsystems: .httpRequests
                    )
                }
            }

            return URLQueryItem(name: key, value: String(describing: value))
        }

        return bodyQueryItems
    }

    open func deleteReaction(id: String, type: String, userId: String?) async throws -> StreamChatReactionRemovalResponse {
        var path = "/messages/{id}/reaction/{type}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let userId {
            let userIdValue = String(userId)
            let userIdQueryItem = URLQueryItem(name: "userId", value: userIdValue)
            queryParams.append(userIdQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatReactionRemovalResponse.self, from: $0)
        }
    }

    open func unmuteUser(unmuteUserRequest: StreamChatUnmuteUserRequest) async throws -> StreamChatUnmuteResponse {
        let path = "/moderation/unmute"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: unmuteUserRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUnmuteResponse.self, from: $0)
        }
    }

    open func sync(syncRequest: StreamChatSyncRequest, withInaccessibleCids: Bool?, watch: Bool?, connectionId: String?) async throws -> StreamChatSyncResponse {
        let path = "/sync"
        
        var queryParams = [URLQueryItem]()
        
        if let withInaccessibleCids {
            let withInaccessibleCidsValue = String(withInaccessibleCids)
            let withInaccessibleCidsQueryItem = URLQueryItem(name: "withInaccessibleCids", value: withInaccessibleCidsValue)
            queryParams.append(withInaccessibleCidsQueryItem)
        }
        if let watch {
            let watchValue = String(watch)
            let watchQueryItem = URLQueryItem(name: "watch", value: watchValue)
            queryParams.append(watchQueryItem)
        }
        if let connectionId {
            let connectionIdValue = String(connectionId)
            let connectionIdQueryItem = URLQueryItem(name: "connectionId", value: connectionIdValue)
            queryParams.append(connectionIdQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: syncRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatSyncResponse.self, from: $0)
        }
    }

    open func queryChannels(queryChannelsRequest: StreamChatQueryChannelsRequest, connectionId: String?) async throws -> StreamChatChannelsResponse {
        let path = "/channels"
        
        var queryParams = [URLQueryItem]()
        
        if let connectionId {
            let connectionIdValue = String(connectionId)
            let connectionIdQueryItem = URLQueryItem(name: "connectionId", value: connectionIdValue)
            queryParams.append(connectionIdQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: queryChannelsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatChannelsResponse.self, from: $0)
        }
    }

    open func deleteChannels(deleteChannelsRequest: StreamChatDeleteChannelsRequest) async throws -> StreamChatDeleteChannelsResponse {
        let path = "/channels/delete"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: deleteChannelsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatDeleteChannelsResponse.self, from: $0)
        }
    }

    open func createCall(type: String, id: String, createCallRequest: StreamChatCreateCallRequest) async throws -> StreamChatCreateCallResponse {
        var path = "/channels/{type}/{id}/call"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: createCallRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatCreateCallResponse.self, from: $0)
        }
    }

    open func runMessageAction(id: String, messageActionRequest: StreamChatMessageActionRequest) async throws -> StreamChatMessageResponse {
        var path = "/messages/{id}/action"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: messageActionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMessageResponse.self, from: $0)
        }
    }

    open func queryUsers(payload: StreamChatQueryUsersRequest?) async throws -> StreamChatUsersResponse {
        let path = "/users"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUsersResponse.self, from: $0)
        }
    }

    open func updateUsers(updateUsersRequest: StreamChatUpdateUsersRequest) async throws -> StreamChatUpdateUsersResponse {
        let path = "/users"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: updateUsersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateUsersResponse.self, from: $0)
        }
    }

    open func updateUsersPartial(updateUserPartialRequest: StreamChatUpdateUserPartialRequest) async throws -> StreamChatUpdateUsersResponse {
        let path = "/users"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "PATCH",
            request: updateUserPartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateUsersResponse.self, from: $0)
        }
    }

    open func showChannel(type: String, id: String, showChannelRequest: StreamChatShowChannelRequest) async throws -> StreamChatShowChannelResponse {
        var path = "/channels/{type}/{id}/show"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: showChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatShowChannelResponse.self, from: $0)
        }
    }

    open func markUnread(type: String, id: String, markUnreadRequest: StreamChatMarkUnreadRequest) async throws -> StreamChatResponse {
        var path = "/channels/{type}/{id}/unread"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: markUnreadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatResponse.self, from: $0)
        }
    }

    open func getOG(url: String?) async throws -> StreamChatGetOGResponse {
        let path = "/og"
        
        var queryParams = [URLQueryItem]()
        
        if let url {
            let urlValue = String(url)
            let urlQueryItem = URLQueryItem(name: "url", value: urlValue)
            queryParams.append(urlQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetOGResponse.self, from: $0)
        }
    }

    open func search(payload: StreamChatSearchRequest?) async throws -> StreamChatSearchResponse {
        let path = "/search"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatSearchResponse.self, from: $0)
        }
    }

    open func markRead(type: String, id: String, markReadRequest: StreamChatMarkReadRequest) async throws -> StreamChatMarkReadResponse {
        var path = "/channels/{type}/{id}/read"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: markReadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMarkReadResponse.self, from: $0)
        }
    }

    open func unmuteChannel(unmuteChannelRequest: StreamChatUnmuteChannelRequest) async throws -> StreamChatUnmuteResponse {
        let path = "/moderation/unmute/channel"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: unmuteChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUnmuteResponse.self, from: $0)
        }
    }

    open func unreadCounts() async throws -> StreamChatUnreadCountsResponse {
        let path = "/unread"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUnreadCountsResponse.self, from: $0)
        }
    }

    open func truncateChannel(type: String, id: String, truncateChannelRequest: StreamChatTruncateChannelRequest) async throws -> StreamChatTruncateChannelResponse {
        var path = "/channels/{type}/{id}/truncate"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: truncateChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatTruncateChannelResponse.self, from: $0)
        }
    }

    open func queryMembers(payload: StreamChatQueryMembersRequest?) async throws -> StreamChatMembersResponse {
        let path = "/members"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMembersResponse.self, from: $0)
        }
    }

    open func sendReaction(id: String, sendReactionRequest: StreamChatSendReactionRequest) async throws -> StreamChatReactionResponse {
        var path = "/messages/{id}/reaction"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: sendReactionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatReactionResponse.self, from: $0)
        }
    }

    open func muteUser(muteUserRequest: StreamChatMuteUserRequest) async throws -> StreamChatMuteUserResponse {
        let path = "/moderation/mute"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: muteUserRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMuteUserResponse.self, from: $0)
        }
    }

    open func getApp() async throws -> StreamChatGetApplicationResponse {
        let path = "/app"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetApplicationResponse.self, from: $0)
        }
    }

    open func getCallToken(callId: String, getCallTokenRequest: StreamChatGetCallTokenRequest) async throws -> StreamChatGetCallTokenResponse {
        var path = "/calls/{call_id}"
        
        let callIdPreEscape = "\(APIHelper.mapValueToPathItem(callId))"
        let callIdPostEscape = callIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "callId"), with: callIdPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: getCallTokenRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetCallTokenResponse.self, from: $0)
        }
    }

    open func updateChannel(type: String, id: String, updateChannelRequest: StreamChatUpdateChannelRequest) async throws -> StreamChatUpdateChannelResponse {
        var path = "/channels/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: updateChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateChannelResponse.self, from: $0)
        }
    }

    open func deleteChannel(type: String, id: String, hardDelete: Bool?) async throws -> StreamChatDeleteChannelResponse {
        var path = "/channels/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let hardDelete {
            let hardDeleteValue = String(hardDelete)
            let hardDeleteQueryItem = URLQueryItem(name: "hardDelete", value: hardDeleteValue)
            queryParams.append(hardDeleteQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatDeleteChannelResponse.self, from: $0)
        }
    }

    open func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: StreamChatUpdateChannelPartialRequest) async throws -> StreamChatUpdateChannelPartialResponse {
        var path = "/channels/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "PATCH",
            request: updateChannelPartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateChannelPartialResponse.self, from: $0)
        }
    }

    open func uploadImage(type: String, id: String, imageUploadRequest: StreamChatImageUploadRequest) async throws -> StreamChatImageUploadResponse {
        var path = "/channels/{type}/{id}/image"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: imageUploadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatImageUploadResponse.self, from: $0)
        }
    }

    open func deleteImage(type: String, id: String, url: String?) async throws -> StreamChatFileDeleteResponse {
        var path = "/channels/{type}/{id}/image"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let url {
            let urlValue = String(url)
            let urlQueryItem = URLQueryItem(name: "url", value: urlValue)
            queryParams.append(urlQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFileDeleteResponse.self, from: $0)
        }
    }

    open func muteChannel(muteChannelRequest: StreamChatMuteChannelRequest) async throws -> StreamChatMuteChannelResponse {
        let path = "/moderation/mute/channel"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: muteChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMuteChannelResponse.self, from: $0)
        }
    }

    open func queryBannedUsers(payload: StreamChatQueryBannedUsersRequest?) async throws -> StreamChatQueryBannedUsersResponse {
        let path = "/query_banned_users"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatQueryBannedUsersResponse.self, from: $0)
        }
    }

    open func getOrCreateChannel(type: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, connectionId: String?) async throws -> StreamChatChannelStateResponse {
        var path = "/channels/{type}/query"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let connectionId {
            let connectionIdValue = String(connectionId)
            let connectionIdQueryItem = URLQueryItem(name: "connectionId", value: connectionIdValue)
            queryParams.append(connectionIdQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: channelGetOrCreateRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatChannelStateResponse.self, from: $0)
        }
    }

    open func stopWatchingChannel(type: String, id: String, channelStopWatchingRequest: StreamChatChannelStopWatchingRequest, connectionId: String?) async throws -> StreamChatStopWatchingResponse {
        var path = "/channels/{type}/{id}/stop-watching"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let connectionId {
            let connectionIdValue = String(connectionId)
            let connectionIdQueryItem = URLQueryItem(name: "connectionId", value: connectionIdValue)
            queryParams.append(connectionIdQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: channelStopWatchingRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatStopWatchingResponse.self, from: $0)
        }
    }

    open func getReactions(id: String, limit: Int?, offset: Int?) async throws -> StreamChatGetReactionsResponse {
        var path = "/messages/{id}/reactions"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let limit {
            let limitValue = String(limit)
            let limitQueryItem = URLQueryItem(name: "limit", value: limitValue)
            queryParams.append(limitQueryItem)
        }
        if let offset {
            let offsetValue = String(offset)
            let offsetQueryItem = URLQueryItem(name: "offset", value: offsetValue)
            queryParams.append(offsetQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetReactionsResponse.self, from: $0)
        }
    }

    open func getReplies(parentId: String, idGte: String?, idGt: String?, idLte: String?, idLt: String?, createdAtAfterOrEqual: String?, createdAtAfter: String?, createdAtBeforeOrEqual: String?, createdAtBefore: String?, idAround: String?, createdAtAround: String?) async throws -> StreamChatGetRepliesResponse {
        var path = "/messages/{parent_id}/replies"
        
        let parentIdPreEscape = "\(APIHelper.mapValueToPathItem(parentId))"
        let parentIdPostEscape = parentIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "parentId"), with: parentIdPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let idGte {
            let idGteValue = String(idGte)
            let idGteQueryItem = URLQueryItem(name: "idGte", value: idGteValue)
            queryParams.append(idGteQueryItem)
        }
        if let idGt {
            let idGtValue = String(idGt)
            let idGtQueryItem = URLQueryItem(name: "idGt", value: idGtValue)
            queryParams.append(idGtQueryItem)
        }
        if let idLte {
            let idLteValue = String(idLte)
            let idLteQueryItem = URLQueryItem(name: "idLte", value: idLteValue)
            queryParams.append(idLteQueryItem)
        }
        if let idLt {
            let idLtValue = String(idLt)
            let idLtQueryItem = URLQueryItem(name: "idLt", value: idLtValue)
            queryParams.append(idLtQueryItem)
        }
        if let createdAtAfterOrEqual {
            let createdAtAfterOrEqualValue = String(createdAtAfterOrEqual)
            let createdAtAfterOrEqualQueryItem = URLQueryItem(name: "createdAtAfterOrEqual", value: createdAtAfterOrEqualValue)
            queryParams.append(createdAtAfterOrEqualQueryItem)
        }
        if let createdAtAfter {
            let createdAtAfterValue = String(createdAtAfter)
            let createdAtAfterQueryItem = URLQueryItem(name: "createdAtAfter", value: createdAtAfterValue)
            queryParams.append(createdAtAfterQueryItem)
        }
        if let createdAtBeforeOrEqual {
            let createdAtBeforeOrEqualValue = String(createdAtBeforeOrEqual)
            let createdAtBeforeOrEqualQueryItem = URLQueryItem(name: "createdAtBeforeOrEqual", value: createdAtBeforeOrEqualValue)
            queryParams.append(createdAtBeforeOrEqualQueryItem)
        }
        if let createdAtBefore {
            let createdAtBeforeValue = String(createdAtBefore)
            let createdAtBeforeQueryItem = URLQueryItem(name: "createdAtBefore", value: createdAtBeforeValue)
            queryParams.append(createdAtBeforeQueryItem)
        }
        if let idAround {
            let idAroundValue = String(idAround)
            let idAroundQueryItem = URLQueryItem(name: "idAround", value: idAroundValue)
            queryParams.append(idAroundQueryItem)
        }
        if let createdAtAround {
            let createdAtAroundValue = String(createdAtAround)
            let createdAtAroundQueryItem = URLQueryItem(name: "createdAtAround", value: createdAtAroundValue)
            queryParams.append(createdAtAroundQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetRepliesResponse.self, from: $0)
        }
    }

    open func sendEvent(type: String, id: String, sendEventRequest: StreamChatSendEventRequest) async throws -> StreamChatEventResponse {
        var path = "/channels/{type}/{id}/event"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: sendEventRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatEventResponse.self, from: $0)
        }
    }

    open func createGuest(guestRequest: StreamChatGuestRequest) async throws -> StreamChatGuestResponse {
        let path = "/guest"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: guestRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGuestResponse.self, from: $0)
        }
    }

    open func queryMessageFlags(payload: StreamChatQueryMessageFlagsRequest?) async throws -> StreamChatQueryMessageFlagsResponse {
        let path = "/moderation/flags/message"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatQueryMessageFlagsResponse.self, from: $0)
        }
    }

    open func listDevices(userId: String?) async throws -> StreamChatListDevicesResponse {
        let path = "/devices"
        
        var queryParams = [URLQueryItem]()
        
        if let userId {
            let userIdValue = String(userId)
            let userIdQueryItem = URLQueryItem(name: "userId", value: userIdValue)
            queryParams.append(userIdQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatListDevicesResponse.self, from: $0)
        }
    }

    open func createDevice(createDeviceRequest: StreamChatCreateDeviceRequest) async throws -> EmptyResponse {
        let path = "/devices"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: createDeviceRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EmptyResponse.self, from: $0)
        }
    }

    open func deleteDevice(id: String?, userId: String?) async throws -> StreamChatResponse {
        let path = "/devices"
        
        var queryParams = [URLQueryItem]()
        
        if let id {
            let idValue = String(id)
            let idQueryItem = URLQueryItem(name: "id", value: idValue)
            queryParams.append(idQueryItem)
        }
        if let userId {
            let userIdValue = String(userId)
            let userIdQueryItem = URLQueryItem(name: "userId", value: userIdValue)
            queryParams.append(userIdQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatResponse.self, from: $0)
        }
    }

    open func translateMessage(id: String, translateMessageRequest: StreamChatTranslateMessageRequest) async throws -> StreamChatMessageResponse {
        var path = "/messages/{id}/translate"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: translateMessageRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMessageResponse.self, from: $0)
        }
    }

    open func flag(flagRequest: StreamChatFlagRequest) async throws -> StreamChatFlagResponse {
        let path = "/moderation/flag"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: flagRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFlagResponse.self, from: $0)
        }
    }

    open func hideChannel(type: String, id: String, hideChannelRequest: StreamChatHideChannelRequest) async throws -> StreamChatHideChannelResponse {
        var path = "/channels/{type}/{id}/hide"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: hideChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatHideChannelResponse.self, from: $0)
        }
    }

    open func sendMessage(type: String, id: String, sendMessageRequest: StreamChatSendMessageRequest) async throws -> StreamChatSendMessageResponse {
        var path = "/channels/{type}/{id}/message"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: sendMessageRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatSendMessageResponse.self, from: $0)
        }
    }

    open func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, connectionId: String?) async throws -> StreamChatChannelStateResponse {
        var path = "/channels/{type}/{id}/query"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let connectionId {
            let connectionIdValue = String(connectionId)
            let connectionIdQueryItem = URLQueryItem(name: "connectionId", value: connectionIdValue)
            queryParams.append(connectionIdQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: channelGetOrCreateRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatChannelStateResponse.self, from: $0)
        }
    }

    open func connect(json: StreamChatConnectRequest?) async throws -> EmptyResponse {
        let path = "/connect"
        
        var queryParams = [URLQueryItem]()
        
        if let json, let jsonQueryParams = try? encodeJSONToQueryItems(data: json) {
            queryParams.append(contentsOf: jsonQueryParams)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EmptyResponse.self, from: $0)
        }
    }

    open func longPoll(connectionId: String?, json: StreamChatConnectRequest?) async throws -> EmptyResponse {
        let path = "/longpoll"
        
        var queryParams = [URLQueryItem]()
        
        if let connectionId {
            let connectionIdValue = String(connectionId)
            let connectionIdQueryItem = URLQueryItem(name: "connectionId", value: connectionIdValue)
            queryParams.append(connectionIdQueryItem)
        }
        if let json, let jsonQueryParams = try? encodeJSONToQueryItems(data: json) {
            queryParams.append(contentsOf: jsonQueryParams)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EmptyResponse.self, from: $0)
        }
    }

    open func getMessage(id: String) async throws -> StreamChatMessageWithPendingMetadataResponse {
        var path = "/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMessageWithPendingMetadataResponse.self, from: $0)
        }
    }

    open func updateMessage(id: String, updateMessageRequest: StreamChatUpdateMessageRequest) async throws -> StreamChatUpdateMessageResponse {
        var path = "/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: updateMessageRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateMessageResponse.self, from: $0)
        }
    }

    open func updateMessagePartial(id: String, updateMessagePartialRequest: StreamChatUpdateMessagePartialRequest) async throws -> StreamChatUpdateMessagePartialResponse {
        var path = "/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "PUT",
            request: updateMessagePartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateMessagePartialResponse.self, from: $0)
        }
    }

    open func deleteMessage(id: String, hard: Bool?, deletedBy: String?) async throws -> StreamChatMessageResponse {
        var path = "/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let hard {
            let hardValue = String(hard)
            let hardQueryItem = URLQueryItem(name: "hard", value: hardValue)
            queryParams.append(hardQueryItem)
        }
        if let deletedBy {
            let deletedByValue = String(deletedBy)
            let deletedByQueryItem = URLQueryItem(name: "deletedBy", value: deletedByValue)
            queryParams.append(deletedByQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMessageResponse.self, from: $0)
        }
    }

    open func ban(banRequest: StreamChatBanRequest) async throws -> StreamChatResponse {
        let path = "/moderation/ban"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: banRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatResponse.self, from: $0)
        }
    }

    open func unban(targetUserId: String?, type: String?, id: String?, createdBy: String?) async throws -> StreamChatResponse {
        let path = "/moderation/ban"
        
        var queryParams = [URLQueryItem]()
        
        if let targetUserId {
            let targetUserIdValue = String(targetUserId)
            let targetUserIdQueryItem = URLQueryItem(name: "targetUserId", value: targetUserIdValue)
            queryParams.append(targetUserIdQueryItem)
        }
        if let type {
            let typeValue = String(type)
            let typeQueryItem = URLQueryItem(name: "type", value: typeValue)
            queryParams.append(typeQueryItem)
        }
        if let id {
            let idValue = String(id)
            let idQueryItem = URLQueryItem(name: "id", value: idValue)
            queryParams.append(idQueryItem)
        }
        if let createdBy {
            let createdByValue = String(createdBy)
            let createdByQueryItem = URLQueryItem(name: "createdBy", value: createdByValue)
            queryParams.append(createdByQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatResponse.self, from: $0)
        }
    }

    open func getCallToken(getCallTokenRequest: StreamChatGetCallTokenRequest) async throws -> StreamChatGetCallTokenResponse {
        let path = "/calls"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: getCallTokenRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetCallTokenResponse.self, from: $0)
        }
    }

    open func markChannelsRead(markChannelsReadRequest: StreamChatMarkChannelsReadRequest) async throws -> StreamChatMarkReadResponse {
        let path = "/channels/read"
        
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: markChannelsReadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMarkReadResponse.self, from: $0)
        }
    }

    open func uploadFile(type: String, id: String, fileUploadRequest: StreamChatFileUploadRequest) async throws -> StreamChatFileUploadResponse {
        var path = "/channels/{type}/{id}/file"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            request: fileUploadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFileUploadResponse.self, from: $0)
        }
    }

    open func deleteFile(type: String, id: String, url: String?) async throws -> StreamChatFileDeleteResponse {
        var path = "/channels/{type}/{id}/file"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let url {
            let urlValue = String(url)
            let urlQueryItem = URLQueryItem(name: "url", value: urlValue)
            queryParams.append(urlQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFileDeleteResponse.self, from: $0)
        }
    }

    open func getManyMessages(type: String, id: String, ids: [String]?) async throws -> StreamChatGetManyMessagesResponse {
        var path = "/channels/{type}/{id}/messages"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let ids {
            let idsValue = ids.joined(separator: ",")
            let idsQueryItem = URLQueryItem(name: "ids", value: idsValue)
            queryParams.append(idsQueryItem)
        }
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET"
        )
        
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetManyMessagesResponse.self, from: $0)
        }
    }
}
