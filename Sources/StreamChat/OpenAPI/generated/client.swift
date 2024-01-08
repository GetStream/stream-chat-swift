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

    open func flag(flagRequest: StreamChatFlagRequest) async throws -> StreamChatFlagResponse {
        let path = "/api/v2/chat/moderation/flag"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFlagResponse.self, from: $0)
        }
    }

    open func queryMessageFlags(payload: StreamChatQueryMessageFlagsRequest?) async throws -> StreamChatQueryMessageFlagsResponse {
        var path = "/api/v2/chat/moderation/flags/message"
        path += "?payload=\(String(describing: payload))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatQueryMessageFlagsResponse.self, from: $0)
        }
    }

    open func unmuteUser(unmuteUserRequest: StreamChatUnmuteUserRequest) async throws -> StreamChatUnmuteResponse {
        let path = "/api/v2/chat/moderation/unmute"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUnmuteResponse.self, from: $0)
        }
    }

    open func queryUsers(payload: StreamChatQueryUsersRequest?) async throws -> StreamChatUsersResponse {
        var path = "/api/v2/users"
        path += "?payload=\(String(describing: payload))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUsersResponse.self, from: $0)
        }
    }

    open func updateUsers(updateUsersRequest: StreamChatUpdateUsersRequest) async throws -> StreamChatUpdateUsersResponse {
        let path = "/api/v2/users"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateUsersResponse.self, from: $0)
        }
    }

    open func updateUsersPartial(updateUserPartialRequest: StreamChatUpdateUserPartialRequest) async throws -> StreamChatUpdateUsersResponse {
        let path = "/api/v2/users"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateUsersResponse.self, from: $0)
        }
    }

    open func updateChannel(type: String, id: String, updateChannelRequest: StreamChatUpdateChannelRequest) async throws -> StreamChatUpdateChannelResponse {
        let path = "/api/v2/chat/channels/{type}/{id}"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateChannelResponse.self, from: $0)
        }
    }

    open func deleteChannel(type: String, id: String, hardDelete: Bool?) async throws -> StreamChatDeleteChannelResponse {
        var path = "/api/v2/chat/channels/{type}/{id}"
        path += "?hardDelete=\(String(describing: hardDelete))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatDeleteChannelResponse.self, from: $0)
        }
    }

    open func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: StreamChatUpdateChannelPartialRequest) async throws -> StreamChatUpdateChannelPartialResponse {
        let path = "/api/v2/chat/channels/{type}/{id}"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateChannelPartialResponse.self, from: $0)
        }
    }

    open func uploadFile(type: String, id: String, fileUploadRequest: StreamChatFileUploadRequest) async throws -> StreamChatFileUploadResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/file"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFileUploadResponse.self, from: $0)
        }
    }

    open func deleteFile(type: String, id: String, url: String?) async throws -> StreamChatFileDeleteResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/file"
        path += "?url=\(String(describing: url))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFileDeleteResponse.self, from: $0)
        }
    }

    open func getMessage(id: String) async throws -> StreamChatMessageWithPendingMetadataResponse {
        let path = "/api/v2/chat/messages/{id}"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMessageWithPendingMetadataResponse.self, from: $0)
        }
    }

    open func updateMessage(id: String, updateMessageRequest: StreamChatUpdateMessageRequest) async throws -> StreamChatUpdateMessageResponse {
        let path = "/api/v2/chat/messages/{id}"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateMessageResponse.self, from: $0)
        }
    }

    open func updateMessagePartial(id: String, updateMessagePartialRequest: StreamChatUpdateMessagePartialRequest) async throws -> StreamChatUpdateMessagePartialResponse {
        let path = "/api/v2/chat/messages/{id}"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PUT"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUpdateMessagePartialResponse.self, from: $0)
        }
    }

    open func deleteMessage(id: String, hard: Bool?, deletedBy: String?) async throws -> StreamChatMessageResponse {
        var path = "/api/v2/chat/messages/{id}"
        path += "?hard=\(String(describing: hard))&deletedBy=\(String(describing: deletedBy))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMessageResponse.self, from: $0)
        }
    }

    open func getOG(url: String?) async throws -> StreamChatGetOGResponse {
        var path = "/api/v2/og"
        path += "?url=\(String(describing: url))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetOGResponse.self, from: $0)
        }
    }

    open func getApp() async throws -> StreamChatGetApplicationResponse {
        let path = "/api/v2/app"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetApplicationResponse.self, from: $0)
        }
    }

    open func runMessageAction(id: String, messageActionRequest: StreamChatMessageActionRequest) async throws -> StreamChatMessageResponse {
        let path = "/api/v2/chat/messages/{id}/action"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMessageResponse.self, from: $0)
        }
    }

    open func listDevices(userId: String?) async throws -> StreamChatListDevicesResponse {
        var path = "/api/v2/devices"
        path += "?userId=\(String(describing: userId))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatListDevicesResponse.self, from: $0)
        }
    }

    open func createDevice(createDeviceRequest: StreamChatCreateDeviceRequest) async throws -> EmptyResponse {
        let path = "/api/v2/devices"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EmptyResponse.self, from: $0)
        }
    }

    open func deleteDevice(id: String?, userId: String?) async throws -> StreamChatResponse {
        var path = "/api/v2/devices"
        path += "?id=\(String(describing: id))&userId=\(String(describing: userId))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatResponse.self, from: $0)
        }
    }

    open func queryBannedUsers(payload: StreamChatQueryBannedUsersRequest?) async throws -> StreamChatQueryBannedUsersResponse {
        var path = "/api/v2/chat/query_banned_users"
        path += "?payload=\(String(describing: payload))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatQueryBannedUsersResponse.self, from: $0)
        }
    }

    open func uploadImage(type: String, id: String, imageUploadRequest: StreamChatImageUploadRequest) async throws -> StreamChatImageUploadResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/image"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatImageUploadResponse.self, from: $0)
        }
    }

    open func deleteImage(type: String, id: String, url: String?) async throws -> StreamChatFileDeleteResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/image"
        path += "?url=\(String(describing: url))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFileDeleteResponse.self, from: $0)
        }
    }

    open func sendMessage(type: String, id: String, sendMessageRequest: StreamChatSendMessageRequest) async throws -> StreamChatSendMessageResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/message"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatSendMessageResponse.self, from: $0)
        }
    }

    open func translateMessage(id: String, translateMessageRequest: StreamChatTranslateMessageRequest) async throws -> StreamChatMessageResponse {
        let path = "/api/v2/chat/messages/{id}/translate"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMessageResponse.self, from: $0)
        }
    }

    open func markRead(type: String, id: String, markReadRequest: StreamChatMarkReadRequest) async throws -> StreamChatMarkReadResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/read"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMarkReadResponse.self, from: $0)
        }
    }

    open func getReactions(id: String, limit: Int?, offset: Int?) async throws -> StreamChatGetReactionsResponse {
        var path = "/api/v2/chat/messages/{id}/reactions"
        path += "?limit=\(String(describing: limit))&offset=\(String(describing: offset))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetReactionsResponse.self, from: $0)
        }
    }

    open func ban(banRequest: StreamChatBanRequest) async throws -> StreamChatResponse {
        let path = "/api/v2/chat/moderation/ban"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatResponse.self, from: $0)
        }
    }

    open func unban(targetUserId: String?, type: String?, id: String?, createdBy: String?) async throws -> StreamChatResponse {
        var path = "/api/v2/chat/moderation/ban"
        path += "?targetUserId=\(String(describing: targetUserId))&type=\(String(describing: type))&id=\(String(describing: id))&createdBy=\(String(describing: createdBy))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatResponse.self, from: $0)
        }
    }

    open func unflag(flagRequest: StreamChatFlagRequest) async throws -> StreamChatFlagResponse {
        let path = "/api/v2/chat/moderation/unflag"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatFlagResponse.self, from: $0)
        }
    }

    open func search(payload: StreamChatSearchRequest?) async throws -> StreamChatSearchResponse {
        var path = "/api/v2/chat/search"
        path += "?payload=\(String(describing: payload))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatSearchResponse.self, from: $0)
        }
    }

    open func deleteChannels(deleteChannelsRequest: StreamChatDeleteChannelsRequest) async throws -> StreamChatDeleteChannelsResponse {
        let path = "/api/v2/chat/channels/delete"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatDeleteChannelsResponse.self, from: $0)
        }
    }

    open func getOrCreateChannel(type: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, connectionId: String?) async throws -> StreamChatChannelStateResponse {
        var path = "/api/v2/chat/channels/{type}/query"
        path += "?connectionId=\(String(describing: connectionId))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatChannelStateResponse.self, from: $0)
        }
    }

    open func getManyMessages(type: String, id: String, ids: [String]?) async throws -> StreamChatGetManyMessagesResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/messages"
        path += "?ids=\(String(describing: ids))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetManyMessagesResponse.self, from: $0)
        }
    }

    open func sendReaction(id: String, sendReactionRequest: StreamChatSendReactionRequest) async throws -> StreamChatReactionResponse {
        let path = "/api/v2/chat/messages/{id}/reaction"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatReactionResponse.self, from: $0)
        }
    }

    open func deleteReaction(id: String, type: String, userId: String?) async throws -> StreamChatReactionRemovalResponse {
        var path = "/api/v2/chat/messages/{id}/reaction/{type}"
        path += "?userId=\(String(describing: userId))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatReactionRemovalResponse.self, from: $0)
        }
    }

    open func getReplies(parentId: String, idGte: String?, idGt: String?, idLte: String?, idLt: String?, createdAtAfterOrEqual: String?, createdAtAfter: String?, createdAtBeforeOrEqual: String?, createdAtBefore: String?, idAround: String?, createdAtAround: String?) async throws -> StreamChatGetRepliesResponse {
        var path = "/api/v2/chat/messages/{parent_id}/replies"
        path += "?idGte=\(String(describing: idGte))&idGt=\(String(describing: idGt))&idLte=\(String(describing: idLte))&idLt=\(String(describing: idLt))&createdAtAfterOrEqual=\(String(describing: createdAtAfterOrEqual))&createdAtAfter=\(String(describing: createdAtAfter))&createdAtBeforeOrEqual=\(String(describing: createdAtBeforeOrEqual))&createdAtBefore=\(String(describing: createdAtBefore))&idAround=\(String(describing: idAround))&createdAtAround=\(String(describing: createdAtAround))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGetRepliesResponse.self, from: $0)
        }
    }

    open func longPoll(connectionId: String?, json: StreamChatConnectRequest?) async throws -> EmptyResponse {
        var path = "/api/v2/longpoll"
        path += "?connectionId=\(String(describing: connectionId))&json=\(String(describing: json))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EmptyResponse.self, from: $0)
        }
    }

    open func queryChannels(queryChannelsRequest: StreamChatQueryChannelsRequest, connectionId: String?) async throws -> StreamChatChannelsResponse {
        var path = "/api/v2/chat/channels"
        path += "?connectionId=\(String(describing: connectionId))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatChannelsResponse.self, from: $0)
        }
    }

    open func markChannelsRead(markChannelsReadRequest: StreamChatMarkChannelsReadRequest) async throws -> StreamChatMarkReadResponse {
        let path = "/api/v2/chat/channels/read"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMarkReadResponse.self, from: $0)
        }
    }

    open func truncateChannel(type: String, id: String, truncateChannelRequest: StreamChatTruncateChannelRequest) async throws -> StreamChatTruncateChannelResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/truncate"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatTruncateChannelResponse.self, from: $0)
        }
    }

    open func stopWatchingChannel(type: String, id: String, channelStopWatchingRequest: StreamChatChannelStopWatchingRequest, connectionId: String?) async throws -> StreamChatStopWatchingResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/stop-watching"
        path += "?connectionId=\(String(describing: connectionId))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatStopWatchingResponse.self, from: $0)
        }
    }

    open func muteUser(muteUserRequest: StreamChatMuteUserRequest) async throws -> StreamChatMuteUserResponse {
        let path = "/api/v2/chat/moderation/mute"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMuteUserResponse.self, from: $0)
        }
    }

    open func connect(json: StreamChatConnectRequest?) async throws -> EmptyResponse {
        var path = "/api/v2/connect"
        path += "?json=\(String(describing: json))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EmptyResponse.self, from: $0)
        }
    }

    open func muteChannel(muteChannelRequest: StreamChatMuteChannelRequest) async throws -> StreamChatMuteChannelResponse {
        let path = "/api/v2/chat/moderation/mute/channel"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMuteChannelResponse.self, from: $0)
        }
    }

    open func sync(syncRequest: StreamChatSyncRequest, withInaccessibleCids: Bool?, watch: Bool?, connectionId: String?) async throws -> StreamChatSyncResponse {
        var path = "/api/v2/chat/sync"
        path += "?withInaccessibleCids=\(String(describing: withInaccessibleCids))&watch=\(String(describing: watch))&connectionId=\(String(describing: connectionId))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatSyncResponse.self, from: $0)
        }
    }

    open func unreadCounts() async throws -> StreamChatUnreadCountsResponse {
        let path = "/api/v2/chat/unread"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUnreadCountsResponse.self, from: $0)
        }
    }

    open func createGuest(guestRequest: StreamChatGuestRequest) async throws -> StreamChatGuestResponse {
        let path = "/api/v2/guest"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatGuestResponse.self, from: $0)
        }
    }

    open func sendEvent(type: String, id: String, sendEventRequest: StreamChatSendEventRequest) async throws -> StreamChatEventResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/event"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatEventResponse.self, from: $0)
        }
    }

    open func hideChannel(type: String, id: String, hideChannelRequest: StreamChatHideChannelRequest) async throws -> StreamChatHideChannelResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/hide"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatHideChannelResponse.self, from: $0)
        }
    }

    open func showChannel(type: String, id: String, showChannelRequest: StreamChatShowChannelRequest) async throws -> StreamChatShowChannelResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/show"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatShowChannelResponse.self, from: $0)
        }
    }

    open func unmuteChannel(unmuteChannelRequest: StreamChatUnmuteChannelRequest) async throws -> StreamChatUnmuteResponse {
        let path = "/api/v2/chat/moderation/unmute/channel"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatUnmuteResponse.self, from: $0)
        }
    }

    open func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, connectionId: String?) async throws -> StreamChatChannelStateResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/query"
        path += "?connectionId=\(String(describing: connectionId))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatChannelStateResponse.self, from: $0)
        }
    }

    open func markUnread(type: String, id: String, markUnreadRequest: StreamChatMarkUnreadRequest) async throws -> StreamChatResponse {
        let path = "/api/v2/chat/channels/{type}/{id}/unread"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatResponse.self, from: $0)
        }
    }

    open func queryMembers(payload: StreamChatQueryMembersRequest?) async throws -> StreamChatMembersResponse {
        var path = "/api/v2/chat/members"
        path += "?payload=\(String(describing: payload))"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamChatMembersResponse.self, from: $0)
        }
    }
}
