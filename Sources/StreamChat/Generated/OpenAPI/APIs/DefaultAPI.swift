//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

class DefaultAPI: DefaultAPIEndpoints, @unchecked Sendable {
    internal var transport: DefaultAPITransport
    internal var middlewares: [DefaultAPIClientMiddleware]
    internal var basePath: String
    internal var jsonDecoder: JSONDecoder
    internal var jsonEncoder: JSONEncoder

    init(
        basePath: String,
        transport: DefaultAPITransport,
        middlewares: [DefaultAPIClientMiddleware],
        jsonDecoder: JSONDecoder = JSONDecoder.default,
        jsonEncoder: JSONEncoder = JSONEncoder.default
    ) {
        self.basePath = basePath
        self.transport = transport
        self.middlewares = middlewares
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    func send<Response: Codable>(
        request: Request,
        deserializer: (Data) throws -> Response
    ) async throws -> Response {
        // TODO: make this a bit nicer and create an API error to make it easier to handle stuff
        func makeError(_ error: Error) -> Error {
            return error
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
        r.body = try jsonEncoder.encode(request)
        return r
    }

    func getApp() async throws -> GetApplicationResponse {
        let path = "/api/v2/app"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetApplicationResponse.self, from: $0)
        }
    }

    func listBlockLists(team: String?) async throws -> ListBlockListResponse {
        let path = "/api/v2/blocklists"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "team": (wrappedValue: team?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ListBlockListResponse.self, from: $0)
        }
    }

    func createBlockList(createBlockListRequest: CreateBlockListRequest) async throws -> CreateBlockListResponse {
        let path = "/api/v2/blocklists"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createBlockListRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(CreateBlockListResponse.self, from: $0)
        }
    }

    func deleteBlockList(name: String, team: String?) async throws -> Response {
        var path = "/api/v2/blocklists/{name}"

        let namePreEscape = "\(APIHelper.mapValueToPathItem(name))"
        let namePostEscape = namePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "name"), with: namePostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "team": (wrappedValue: team?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func updateBlockList(name: String, updateBlockListRequest: UpdateBlockListRequest) async throws -> UpdateBlockListResponse {
        var path = "/api/v2/blocklists/{name}"

        let namePreEscape = "\(APIHelper.mapValueToPathItem(name))"
        let namePostEscape = namePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "name"), with: namePostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PUT",
            request: updateBlockListRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateBlockListResponse.self, from: $0)
        }
    }

    func queryChannels(queryChannelsRequest: QueryChannelsRequest) async throws -> QueryChannelsResponse {
        let path = "/api/v2/chat/channels"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryChannelsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryChannelsResponse.self, from: $0)
        }
    }

    func deleteChannels(deleteChannelsRequest: DeleteChannelsRequest) async throws -> DeleteChannelsResponse {
        let path = "/api/v2/chat/channels/delete"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: deleteChannelsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteChannelsResponse.self, from: $0)
        }
    }

    func markDelivered(markDeliveredRequest: MarkDeliveredRequest) async throws -> MarkDeliveredResponse {
        let path = "/api/v2/chat/channels/delivered"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: markDeliveredRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MarkDeliveredResponse.self, from: $0)
        }
    }

    func markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest) async throws -> MarkReadResponse {
        let path = "/api/v2/chat/channels/read"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: markChannelsReadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MarkReadResponse.self, from: $0)
        }
    }

    func getOrCreateDistinctChannel(type: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest) async throws -> ChannelStateResponse {
        var path = "/api/v2/chat/channels/{type}/query"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: channelGetOrCreateRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ChannelStateResponse.self, from: $0)
        }
    }

    func deleteChannel(type: String, id: String, hardDelete: Bool?) async throws -> DeleteChannelResponse {
        var path = "/api/v2/chat/channels/{type}/{id}"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "hard_delete": (wrappedValue: hardDelete?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteChannelResponse.self, from: $0)
        }
    }

    func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: UpdateChannelPartialRequest) async throws -> UpdateChannelPartialResponse {
        var path = "/api/v2/chat/channels/{type}/{id}"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH",
            request: updateChannelPartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateChannelPartialResponse.self, from: $0)
        }
    }

    func updateChannel(type: String, id: String, updateChannelRequest: UpdateChannelRequest) async throws -> UpdateChannelResponse {
        var path = "/api/v2/chat/channels/{type}/{id}"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: updateChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateChannelResponse.self, from: $0)
        }
    }

    func deleteDraft(type: String, id: String, parentId: String?) async throws -> Response {
        var path = "/api/v2/chat/channels/{type}/{id}/draft"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "parent_id": (wrappedValue: parentId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func getDraft(type: String, id: String, parentId: String?) async throws -> GetDraftResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/draft"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "parent_id": (wrappedValue: parentId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetDraftResponse.self, from: $0)
        }
    }

    func createDraft(type: String, id: String, createDraftRequest: CreateDraftRequest) async throws -> CreateDraftResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/draft"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createDraftRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(CreateDraftResponse.self, from: $0)
        }
    }

    func sendEvent(type: String, id: String, sendEventRequest: SendEventRequest) async throws -> EventResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/event"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: sendEventRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EventResponse.self, from: $0)
        }
    }

    func deleteChannelFile(type: String, id: String, url: String?) async throws -> Response {
        var path = "/api/v2/chat/channels/{type}/{id}/file"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "url": (wrappedValue: url?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func uploadChannelFile(type: String, id: String, uploadChannelFileRequest: UploadChannelFileRequest) async throws -> UploadChannelFileResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/file"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: uploadChannelFileRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UploadChannelFileResponse.self, from: $0)
        }
    }

    func hideChannel(type: String, id: String, hideChannelRequest: HideChannelRequest) async throws -> HideChannelResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/hide"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: hideChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(HideChannelResponse.self, from: $0)
        }
    }

    func deleteChannelImage(type: String, id: String, url: String?) async throws -> Response {
        var path = "/api/v2/chat/channels/{type}/{id}/image"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "url": (wrappedValue: url?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func uploadChannelImage(type: String, id: String, uploadChannelRequest: UploadChannelRequest) async throws -> UploadChannelResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/image"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: uploadChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UploadChannelResponse.self, from: $0)
        }
    }

    func updateMemberPartial(type: String, id: String, updateMemberPartialRequest: UpdateMemberPartialRequest) async throws -> UpdateMemberPartialResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/member"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH",
            request: updateMemberPartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateMemberPartialResponse.self, from: $0)
        }
    }

    func sendMessage(type: String, id: String, sendMessageRequest: SendMessageRequest) async throws -> SendMessageResponseModel {
        var path = "/api/v2/chat/channels/{type}/{id}/message"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: sendMessageRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SendMessageResponseModel.self, from: $0)
        }
    }

    func getManyMessages(type: String, id: String, ids: [String]) async throws -> GetManyMessagesResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/messages"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "ids": (wrappedValue: ids.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetManyMessagesResponse.self, from: $0)
        }
    }

    func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest) async throws -> ChannelStateResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/query"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: channelGetOrCreateRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ChannelStateResponse.self, from: $0)
        }
    }

    func markRead(type: String, id: String, markReadRequest: MarkReadRequest) async throws -> MarkReadResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/read"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: markReadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MarkReadResponse.self, from: $0)
        }
    }

    func showChannel(type: String, id: String) async throws -> ShowChannelResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/show"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ShowChannelResponse.self, from: $0)
        }
    }

    func stopWatchingChannel(type: String, id: String) async throws -> Response {
        var path = "/api/v2/chat/channels/{type}/{id}/stop-watching"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func truncateChannel(type: String, id: String, truncateChannelRequest: TruncateChannelRequest) async throws -> TruncateChannelResponse {
        var path = "/api/v2/chat/channels/{type}/{id}/truncate"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: truncateChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(TruncateChannelResponse.self, from: $0)
        }
    }

    func markUnread(type: String, id: String, markUnreadRequest: MarkUnreadRequest) async throws -> Response {
        var path = "/api/v2/chat/channels/{type}/{id}/unread"

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: markUnreadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func queryDrafts(queryDraftsRequest: QueryDraftsRequest) async throws -> QueryDraftsResponse {
        let path = "/api/v2/chat/drafts/query"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryDraftsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryDraftsResponse.self, from: $0)
        }
    }

    func queryMembers(payload: QueryMembersPayload?) async throws -> MembersResponse {
        let path = "/api/v2/chat/members"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "payload": (wrappedValue: payload?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MembersResponse.self, from: $0)
        }
    }

    func deleteMessage(id: String, hard: Bool?, deletedBy: String?, deleteForMe: Bool?) async throws -> DeleteMessageResponse {
        var path = "/api/v2/chat/messages/{id}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "hard": (wrappedValue: hard?.encodeToJSON(), isExplode: true),
            "deleted_by": (wrappedValue: deletedBy?.encodeToJSON(), isExplode: true),
            "delete_for_me": (wrappedValue: deleteForMe?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteMessageResponse.self, from: $0)
        }
    }

    func getMessage(id: String) async throws -> GetMessageResponse {
        var path = "/api/v2/chat/messages/{id}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetMessageResponse.self, from: $0)
        }
    }

    func updateMessage(id: String, updateMessageRequest: UpdateMessageRequest) async throws -> UpdateMessageResponse {
        var path = "/api/v2/chat/messages/{id}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: updateMessageRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateMessageResponse.self, from: $0)
        }
    }

    func updateMessagePartial(id: String, updateMessagePartialRequest: UpdateMessagePartialRequest) async throws -> UpdateMessagePartialResponse {
        var path = "/api/v2/chat/messages/{id}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PUT",
            request: updateMessagePartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateMessagePartialResponse.self, from: $0)
        }
    }

    func runMessageAction(id: String, messageActionRequest: MessageActionRequest) async throws -> MessageActionResponse {
        var path = "/api/v2/chat/messages/{id}/action"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: messageActionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MessageActionResponse.self, from: $0)
        }
    }

    func sendReaction(id: String, sendReactionRequest: SendReactionRequest) async throws -> SendReactionResponse {
        var path = "/api/v2/chat/messages/{id}/reaction"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: sendReactionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SendReactionResponse.self, from: $0)
        }
    }

    func deleteReaction(id: String, type: String, userId: String?) async throws -> DeleteReactionResponse {
        var path = "/api/v2/chat/messages/{id}/reaction/{type}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "user_id": (wrappedValue: userId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteReactionResponse.self, from: $0)
        }
    }

    func getReactions(id: String, limit: Int?, offset: Int?) async throws -> GetReactionsResponse {
        var path = "/api/v2/chat/messages/{id}/reactions"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "limit": (wrappedValue: limit?.encodeToJSON(), isExplode: true),
            "offset": (wrappedValue: offset?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetReactionsResponse.self, from: $0)
        }
    }

    func queryReactions(id: String, queryReactionsRequest: QueryReactionsRequest) async throws -> QueryReactionsResponse {
        var path = "/api/v2/chat/messages/{id}/reactions"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryReactionsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryReactionsResponse.self, from: $0)
        }
    }

    func translateMessage(id: String, translateMessageRequest: TranslateMessageRequest) async throws -> MessageActionResponse {
        var path = "/api/v2/chat/messages/{id}/translate"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: translateMessageRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MessageActionResponse.self, from: $0)
        }
    }

    func castPollVote(messageId: String, pollId: String, castPollVoteRequest: CastPollVoteRequest) async throws -> PollVoteResponse {
        var path = "/api/v2/chat/messages/{message_id}/polls/{poll_id}/vote"

        let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
        let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "message_id"), with: messageIdPostEscape, options: .literal, range: nil)
        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: castPollVoteRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollVoteResponse.self, from: $0)
        }
    }

    func deletePollVote(messageId: String, pollId: String, voteId: String, userId: String?) async throws -> PollVoteResponse {
        var path = "/api/v2/chat/messages/{message_id}/polls/{poll_id}/vote/{vote_id}"

        let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
        let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "message_id"), with: messageIdPostEscape, options: .literal, range: nil)
        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)
        let voteIdPreEscape = "\(APIHelper.mapValueToPathItem(voteId))"
        let voteIdPostEscape = voteIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "vote_id"), with: voteIdPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "user_id": (wrappedValue: userId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollVoteResponse.self, from: $0)
        }
    }

    func deleteReminder(messageId: String) async throws -> DeleteReminderResponse {
        var path = "/api/v2/chat/messages/{message_id}/reminders"

        let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
        let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "message_id"), with: messageIdPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteReminderResponse.self, from: $0)
        }
    }

    func updateReminder(messageId: String, updateReminderRequest: UpdateReminderRequest) async throws -> UpdateReminderResponse {
        var path = "/api/v2/chat/messages/{message_id}/reminders"

        let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
        let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "message_id"), with: messageIdPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH",
            request: updateReminderRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateReminderResponse.self, from: $0)
        }
    }

    func createReminder(messageId: String, createReminderRequest: CreateReminderRequest) async throws -> ReminderResponseData {
        var path = "/api/v2/chat/messages/{message_id}/reminders"

        let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
        let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "message_id"), with: messageIdPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createReminderRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ReminderResponseData.self, from: $0)
        }
    }

    func getReplies(parentId: String, limit: Int?, idGte: String?, idGt: String?, idLte: String?, idLt: String?, idAround: String?, sort: [SortParamRequestModel]?) async throws -> GetRepliesResponse {
        var path = "/api/v2/chat/messages/{parent_id}/replies"

        let parentIdPreEscape = "\(APIHelper.mapValueToPathItem(parentId))"
        let parentIdPostEscape = parentIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "parent_id"), with: parentIdPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "limit": (wrappedValue: limit?.encodeToJSON(), isExplode: true),
            "id_gte": (wrappedValue: idGte?.encodeToJSON(), isExplode: true),
            "id_gt": (wrappedValue: idGt?.encodeToJSON(), isExplode: true),
            "id_lte": (wrappedValue: idLte?.encodeToJSON(), isExplode: true),
            "id_lt": (wrappedValue: idLt?.encodeToJSON(), isExplode: true),
            "id_around": (wrappedValue: idAround?.encodeToJSON(), isExplode: true),
            "sort": (wrappedValue: sort?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetRepliesResponse.self, from: $0)
        }
    }

    func queryMessageFlags(payload: QueryMessageFlagsPayload?) async throws -> QueryMessageFlagsResponse {
        let path = "/api/v2/chat/moderation/flags/message"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "payload": (wrappedValue: payload?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryMessageFlagsResponse.self, from: $0)
        }
    }

    func muteChannel(muteChannelRequest: MuteChannelRequest) async throws -> MuteChannelResponse {
        let path = "/api/v2/chat/moderation/mute/channel"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: muteChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MuteChannelResponse.self, from: $0)
        }
    }

    func unmuteChannel(unmuteChannelRequest: UnmuteChannelRequest) async throws -> UnmuteResponse {
        let path = "/api/v2/chat/moderation/unmute/channel"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: unmuteChannelRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UnmuteResponse.self, from: $0)
        }
    }

    func queryBannedUsers(payload: QueryBannedUsersPayload?) async throws -> QueryBannedUsersResponse {
        let path = "/api/v2/chat/query_banned_users"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "payload": (wrappedValue: payload?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryBannedUsersResponse.self, from: $0)
        }
    }

    func queryFutureChannelBans(payload: QueryFutureChannelBansPayload?) async throws -> QueryFutureChannelBansResponse {
        let path = "/api/v2/chat/query_future_channel_bans"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "payload": (wrappedValue: payload?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryFutureChannelBansResponse.self, from: $0)
        }
    }

    func queryReminders(queryRemindersRequest: QueryRemindersRequest) async throws -> QueryRemindersResponse {
        let path = "/api/v2/chat/reminders/query"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryRemindersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryRemindersResponse.self, from: $0)
        }
    }

    func search(payload: SearchPayload?) async throws -> SearchResponse {
        let path = "/api/v2/chat/search"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "payload": (wrappedValue: payload?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SearchResponse.self, from: $0)
        }
    }

    func sync(syncRequest: SyncRequest, withInaccessibleCids: Bool?, watch: Bool?) async throws -> SyncResponse {
        let path = "/api/v2/chat/sync"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "with_inaccessible_cids": (wrappedValue: withInaccessibleCids?.encodeToJSON(), isExplode: true),
            "watch": (wrappedValue: watch?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "POST",
            request: syncRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SyncResponse.self, from: $0)
        }
    }

    func queryThreads(queryThreadsRequest: QueryThreadsRequest) async throws -> QueryThreadsResponse {
        let path = "/api/v2/chat/threads"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryThreadsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryThreadsResponse.self, from: $0)
        }
    }

    func getThread(messageId: String, watch: Bool?, replyLimit: Int?, participantLimit: Int?, memberLimit: Int?) async throws -> GetThreadResponse {
        var path = "/api/v2/chat/threads/{message_id}"

        let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
        let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "message_id"), with: messageIdPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "watch": (wrappedValue: watch?.encodeToJSON(), isExplode: true),
            "reply_limit": (wrappedValue: replyLimit?.encodeToJSON(), isExplode: true),
            "participant_limit": (wrappedValue: participantLimit?.encodeToJSON(), isExplode: true),
            "member_limit": (wrappedValue: memberLimit?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetThreadResponse.self, from: $0)
        }
    }

    func updateThreadPartial(messageId: String, updateThreadPartialRequest: UpdateThreadPartialRequest) async throws -> UpdateThreadPartialResponse {
        var path = "/api/v2/chat/threads/{message_id}"

        let messageIdPreEscape = "\(APIHelper.mapValueToPathItem(messageId))"
        let messageIdPostEscape = messageIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "message_id"), with: messageIdPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH",
            request: updateThreadPartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateThreadPartialResponse.self, from: $0)
        }
    }

    func unreadCounts() async throws -> WrappedUnreadCountsResponse {
        let path = "/api/v2/chat/unread"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(WrappedUnreadCountsResponse.self, from: $0)
        }
    }

    func deleteDevice(id: String) async throws -> Response {
        let path = "/api/v2/devices"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "id": (wrappedValue: id.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func listDevices() async throws -> ListDevicesResponse {
        let path = "/api/v2/devices"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ListDevicesResponse.self, from: $0)
        }
    }

    func createDevice(createDeviceRequest: CreateDeviceRequest) async throws -> Response {
        let path = "/api/v2/devices"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createDeviceRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func createGuest(createGuestRequest: CreateGuestRequest) async throws -> CreateGuestResponse {
        let path = "/api/v2/guest"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createGuestRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(CreateGuestResponse.self, from: $0)
        }
    }

    func longPoll(json: WSAuthMessage?) async throws {
        let path = "/api/v2/longpoll"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "json": (wrappedValue: json?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        _ = try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StreamCore.EmptyResponse.self, from: $0)
        }
    }

    func appeal(appealRequest: AppealRequest) async throws -> AppealResponse {
        let path = "/api/v2/moderation/appeal"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: appealRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(AppealResponse.self, from: $0)
        }
    }

    func getAppeal(id: String) async throws -> GetAppealResponse {
        var path = "/api/v2/moderation/appeal/{id}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetAppealResponse.self, from: $0)
        }
    }

    func queryAppeals(queryAppealsRequest: QueryAppealsRequest) async throws -> QueryAppealsResponse {
        let path = "/api/v2/moderation/appeals"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryAppealsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryAppealsResponse.self, from: $0)
        }
    }

    func ban(banRequest: BanRequest) async throws -> BanResponse {
        let path = "/api/v2/moderation/ban"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: banRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(BanResponse.self, from: $0)
        }
    }

    func upsertConfig(upsertConfigRequest: UpsertConfigRequest) async throws -> UpsertConfigResponse {
        let path = "/api/v2/moderation/config"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: upsertConfigRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpsertConfigResponse.self, from: $0)
        }
    }

    func deleteConfig(key: String, team: String?) async throws -> DeleteModerationConfigResponse {
        var path = "/api/v2/moderation/config/{key}"

        let keyPreEscape = "\(APIHelper.mapValueToPathItem(key))"
        let keyPostEscape = keyPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "key"), with: keyPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "team": (wrappedValue: team?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteModerationConfigResponse.self, from: $0)
        }
    }

    func getConfig(key: String, team: String?) async throws -> GetConfigResponse {
        var path = "/api/v2/moderation/config/{key}"

        let keyPreEscape = "\(APIHelper.mapValueToPathItem(key))"
        let keyPostEscape = keyPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "key"), with: keyPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "team": (wrappedValue: team?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetConfigResponse.self, from: $0)
        }
    }

    func queryModerationConfigs(queryModerationConfigsRequest: QueryModerationConfigsRequest) async throws -> QueryModerationConfigsResponse {
        let path = "/api/v2/moderation/configs"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryModerationConfigsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryModerationConfigsResponse.self, from: $0)
        }
    }

    func flag(flagRequest: FlagRequest) async throws -> FlagResponse {
        let path = "/api/v2/moderation/flag"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: flagRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(FlagResponse.self, from: $0)
        }
    }

    func mute(muteRequest: MuteRequest) async throws -> MuteResponse {
        let path = "/api/v2/moderation/mute"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: muteRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MuteResponse.self, from: $0)
        }
    }

    func queryReviewQueue(queryReviewQueueRequest: QueryReviewQueueRequest) async throws -> QueryReviewQueueResponse {
        let path = "/api/v2/moderation/review_queue"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryReviewQueueRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryReviewQueueResponse.self, from: $0)
        }
    }

    func submitAction(submitActionRequest: SubmitActionRequest) async throws -> SubmitActionResponse {
        let path = "/api/v2/moderation/submit_action"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: submitActionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SubmitActionResponse.self, from: $0)
        }
    }

    func getOG(url: String) async throws -> GetOGResponse {
        let path = "/api/v2/og"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "url": (wrappedValue: url.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetOGResponse.self, from: $0)
        }
    }

    func createPoll(createPollRequest: CreatePollRequest) async throws -> PollResponse {
        let path = "/api/v2/polls"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createPollRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollResponse.self, from: $0)
        }
    }

    func updatePoll(updatePollRequest: UpdatePollRequest) async throws -> PollResponse {
        let path = "/api/v2/polls"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PUT",
            request: updatePollRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollResponse.self, from: $0)
        }
    }

    func queryPolls(userId: String?, queryPollsRequest: QueryPollsRequest) async throws -> QueryPollsResponse {
        let path = "/api/v2/polls/query"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "user_id": (wrappedValue: userId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "POST",
            request: queryPollsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryPollsResponse.self, from: $0)
        }
    }

    func deletePoll(pollId: String, userId: String?) async throws -> Response {
        var path = "/api/v2/polls/{poll_id}"

        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "user_id": (wrappedValue: userId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func getPoll(pollId: String, userId: String?) async throws -> PollResponse {
        var path = "/api/v2/polls/{poll_id}"

        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "user_id": (wrappedValue: userId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollResponse.self, from: $0)
        }
    }

    func updatePollPartial(pollId: String, updatePollPartialRequest: UpdatePollPartialRequest) async throws -> PollResponse {
        var path = "/api/v2/polls/{poll_id}"

        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH",
            request: updatePollPartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollResponse.self, from: $0)
        }
    }

    func createPollOption(pollId: String, createPollOptionRequest: CreatePollOptionRequest) async throws -> PollOptionResponseModel {
        var path = "/api/v2/polls/{poll_id}/options"

        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createPollOptionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollOptionResponseModel.self, from: $0)
        }
    }

    func updatePollOption(pollId: String, updatePollOptionRequest: UpdatePollOptionRequestModel) async throws -> PollOptionResponseModel {
        var path = "/api/v2/polls/{poll_id}/options"

        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PUT",
            request: updatePollOptionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollOptionResponseModel.self, from: $0)
        }
    }

    func deletePollOption(pollId: String, optionId: String, userId: String?) async throws -> Response {
        var path = "/api/v2/polls/{poll_id}/options/{option_id}"

        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)
        let optionIdPreEscape = "\(APIHelper.mapValueToPathItem(optionId))"
        let optionIdPostEscape = optionIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "option_id"), with: optionIdPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "user_id": (wrappedValue: userId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func getPollOption(pollId: String, optionId: String, userId: String?) async throws -> PollOptionResponseModel {
        var path = "/api/v2/polls/{poll_id}/options/{option_id}"

        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)
        let optionIdPreEscape = "\(APIHelper.mapValueToPathItem(optionId))"
        let optionIdPostEscape = optionIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "option_id"), with: optionIdPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "user_id": (wrappedValue: userId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollOptionResponseModel.self, from: $0)
        }
    }

    func queryPollVotes(pollId: String, userId: String?, queryPollVotesRequest: QueryPollVotesRequest) async throws -> PollVotesResponse {
        var path = "/api/v2/polls/{poll_id}/votes"

        let pollIdPreEscape = "\(APIHelper.mapValueToPathItem(pollId))"
        let pollIdPostEscape = pollIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "poll_id"), with: pollIdPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "user_id": (wrappedValue: userId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "POST",
            request: queryPollVotesRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PollVotesResponse.self, from: $0)
        }
    }

    func updatePushNotificationPreferences(upsertPushPreferencesRequest: UpsertPushPreferencesRequest) async throws -> UpsertPushPreferencesResponse {
        let path = "/api/v2/push_preferences"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: upsertPushPreferencesRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpsertPushPreferencesResponse.self, from: $0)
        }
    }

    func deleteFile(url: String?) async throws -> Response {
        let path = "/api/v2/uploads/file"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "url": (wrappedValue: url?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func uploadFile(fileUploadRequest: FileUploadRequest) async throws -> FileUploadResponse {
        let path = "/api/v2/uploads/file"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: fileUploadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(FileUploadResponse.self, from: $0)
        }
    }

    func deleteImage(url: String?) async throws -> Response {
        let path = "/api/v2/uploads/image"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "url": (wrappedValue: url?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func uploadImage(imageUploadRequest: ImageUploadRequest) async throws -> ImageUploadResponse {
        let path = "/api/v2/uploads/image"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: imageUploadRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ImageUploadResponse.self, from: $0)
        }
    }

    func listUserGroups(limit: Int?, idGt: String?, createdAtGt: String?, teamId: String?) async throws -> ListUserGroupsResponse {
        let path = "/api/v2/usergroups"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "limit": (wrappedValue: limit?.encodeToJSON(), isExplode: true),
            "id_gt": (wrappedValue: idGt?.encodeToJSON(), isExplode: true),
            "created_at_gt": (wrappedValue: createdAtGt?.encodeToJSON(), isExplode: true),
            "team_id": (wrappedValue: teamId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ListUserGroupsResponse.self, from: $0)
        }
    }

    func createUserGroup(createUserGroupRequest: CreateUserGroupRequest) async throws -> CreateUserGroupResponse {
        let path = "/api/v2/usergroups"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createUserGroupRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(CreateUserGroupResponse.self, from: $0)
        }
    }

    func searchUserGroups(query: String, limit: Int?, nameGt: String?, idGt: String?, teamId: String?) async throws -> SearchUserGroupsResponse {
        let path = "/api/v2/usergroups/search"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "query": (wrappedValue: query.encodeToJSON(), isExplode: true),
            "limit": (wrappedValue: limit?.encodeToJSON(), isExplode: true),
            "name_gt": (wrappedValue: nameGt?.encodeToJSON(), isExplode: true),
            "id_gt": (wrappedValue: idGt?.encodeToJSON(), isExplode: true),
            "team_id": (wrappedValue: teamId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SearchUserGroupsResponse.self, from: $0)
        }
    }

    func deleteUserGroup(id: String, teamId: String?) async throws -> Response {
        var path = "/api/v2/usergroups/{id}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "team_id": (wrappedValue: teamId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(Response.self, from: $0)
        }
    }

    func getUserGroup(id: String, teamId: String?) async throws -> GetUserGroupResponse {
        var path = "/api/v2/usergroups/{id}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "team_id": (wrappedValue: teamId?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetUserGroupResponse.self, from: $0)
        }
    }

    func updateUserGroup(id: String, updateUserGroupRequest: UpdateUserGroupRequest) async throws -> UpdateUserGroupResponse {
        var path = "/api/v2/usergroups/{id}"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PUT",
            request: updateUserGroupRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateUserGroupResponse.self, from: $0)
        }
    }

    func addUserGroupMembers(id: String, addUserGroupMembersRequest: AddUserGroupMembersRequest) async throws -> AddUserGroupMembersResponse {
        var path = "/api/v2/usergroups/{id}/members"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: addUserGroupMembersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(AddUserGroupMembersResponse.self, from: $0)
        }
    }

    func removeUserGroupMembers(id: String, removeUserGroupMembersRequest: RemoveUserGroupMembersRequest) async throws -> RemoveUserGroupMembersResponse {
        var path = "/api/v2/usergroups/{id}/members/delete"

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: removeUserGroupMembersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(RemoveUserGroupMembersResponse.self, from: $0)
        }
    }

    func queryUsers(payload: QueryUsersPayload?) async throws -> QueryUsersResponse {
        let path = "/api/v2/users"

        let queryParams = APIHelper.mapValuesToQueryItems([
            "payload": (wrappedValue: payload?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryUsersResponse.self, from: $0)
        }
    }

    func updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest) async throws -> UpdateUsersResponse {
        let path = "/api/v2/users"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH",
            request: updateUsersPartialRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateUsersResponse.self, from: $0)
        }
    }

    func updateUsers(updateUsersRequest: UpdateUsersRequest) async throws -> UpdateUsersResponse {
        let path = "/api/v2/users"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: updateUsersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateUsersResponse.self, from: $0)
        }
    }

    func getBlockedUsers() async throws -> GetBlockedUsersResponse {
        let path = "/api/v2/users/block"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetBlockedUsersResponse.self, from: $0)
        }
    }

    func blockUsers(blockUsersRequest: BlockUsersRequest) async throws -> BlockUsersResponse {
        let path = "/api/v2/users/block"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: blockUsersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(BlockUsersResponse.self, from: $0)
        }
    }

    func getUserLiveLocations() async throws -> SharedLocationsResponse {
        let path = "/api/v2/users/live_locations"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SharedLocationsResponse.self, from: $0)
        }
    }

    func updateLiveLocation(updateLiveLocationRequest: UpdateLiveLocationRequest) async throws -> SharedLocationResponse {
        let path = "/api/v2/users/live_locations"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PUT",
            request: updateLiveLocationRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SharedLocationResponse.self, from: $0)
        }
    }

    func unblockUsers(unblockUsersRequest: UnblockUsersRequest) async throws -> UnblockUsersResponse {
        let path = "/api/v2/users/unblock"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: unblockUsersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UnblockUsersResponse.self, from: $0)
        }
    }
}

protocol DefaultAPIEndpoints {
    func getApp() async throws -> GetApplicationResponse

    func listBlockLists(team: String?) async throws -> ListBlockListResponse

    func createBlockList(createBlockListRequest: CreateBlockListRequest) async throws -> CreateBlockListResponse

    func deleteBlockList(name: String, team: String?) async throws -> Response

    func updateBlockList(name: String, updateBlockListRequest: UpdateBlockListRequest) async throws -> UpdateBlockListResponse

    func queryChannels(queryChannelsRequest: QueryChannelsRequest) async throws -> QueryChannelsResponse

    func deleteChannels(deleteChannelsRequest: DeleteChannelsRequest) async throws -> DeleteChannelsResponse

    func markDelivered(markDeliveredRequest: MarkDeliveredRequest) async throws -> MarkDeliveredResponse

    func markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest) async throws -> MarkReadResponse

    func getOrCreateDistinctChannel(type: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest) async throws -> ChannelStateResponse

    func deleteChannel(type: String, id: String, hardDelete: Bool?) async throws -> DeleteChannelResponse

    func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: UpdateChannelPartialRequest) async throws -> UpdateChannelPartialResponse

    func updateChannel(type: String, id: String, updateChannelRequest: UpdateChannelRequest) async throws -> UpdateChannelResponse

    func deleteDraft(type: String, id: String, parentId: String?) async throws -> Response

    func getDraft(type: String, id: String, parentId: String?) async throws -> GetDraftResponse

    func createDraft(type: String, id: String, createDraftRequest: CreateDraftRequest) async throws -> CreateDraftResponse

    func sendEvent(type: String, id: String, sendEventRequest: SendEventRequest) async throws -> EventResponse

    func deleteChannelFile(type: String, id: String, url: String?) async throws -> Response

    func uploadChannelFile(type: String, id: String, uploadChannelFileRequest: UploadChannelFileRequest) async throws -> UploadChannelFileResponse

    func hideChannel(type: String, id: String, hideChannelRequest: HideChannelRequest) async throws -> HideChannelResponse

    func deleteChannelImage(type: String, id: String, url: String?) async throws -> Response

    func uploadChannelImage(type: String, id: String, uploadChannelRequest: UploadChannelRequest) async throws -> UploadChannelResponse

    func updateMemberPartial(type: String, id: String, updateMemberPartialRequest: UpdateMemberPartialRequest) async throws -> UpdateMemberPartialResponse

    func sendMessage(type: String, id: String, sendMessageRequest: SendMessageRequest) async throws -> SendMessageResponseModel

    func getManyMessages(type: String, id: String, ids: [String]) async throws -> GetManyMessagesResponse

    func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: ChannelGetOrCreateRequest) async throws -> ChannelStateResponse

    func markRead(type: String, id: String, markReadRequest: MarkReadRequest) async throws -> MarkReadResponse

    func showChannel(type: String, id: String) async throws -> ShowChannelResponse

    func stopWatchingChannel(type: String, id: String) async throws -> Response

    func truncateChannel(type: String, id: String, truncateChannelRequest: TruncateChannelRequest) async throws -> TruncateChannelResponse

    func markUnread(type: String, id: String, markUnreadRequest: MarkUnreadRequest) async throws -> Response

    func queryDrafts(queryDraftsRequest: QueryDraftsRequest) async throws -> QueryDraftsResponse

    func queryMembers(payload: QueryMembersPayload?) async throws -> MembersResponse

    func deleteMessage(id: String, hard: Bool?, deletedBy: String?, deleteForMe: Bool?) async throws -> DeleteMessageResponse

    func getMessage(id: String) async throws -> GetMessageResponse

    func updateMessage(id: String, updateMessageRequest: UpdateMessageRequest) async throws -> UpdateMessageResponse

    func updateMessagePartial(id: String, updateMessagePartialRequest: UpdateMessagePartialRequest) async throws -> UpdateMessagePartialResponse

    func runMessageAction(id: String, messageActionRequest: MessageActionRequest) async throws -> MessageActionResponse

    func sendReaction(id: String, sendReactionRequest: SendReactionRequest) async throws -> SendReactionResponse

    func deleteReaction(id: String, type: String, userId: String?) async throws -> DeleteReactionResponse

    func getReactions(id: String, limit: Int?, offset: Int?) async throws -> GetReactionsResponse

    func queryReactions(id: String, queryReactionsRequest: QueryReactionsRequest) async throws -> QueryReactionsResponse

    func translateMessage(id: String, translateMessageRequest: TranslateMessageRequest) async throws -> MessageActionResponse

    func castPollVote(messageId: String, pollId: String, castPollVoteRequest: CastPollVoteRequest) async throws -> PollVoteResponse

    func deletePollVote(messageId: String, pollId: String, voteId: String, userId: String?) async throws -> PollVoteResponse

    func deleteReminder(messageId: String) async throws -> DeleteReminderResponse

    func updateReminder(messageId: String, updateReminderRequest: UpdateReminderRequest) async throws -> UpdateReminderResponse

    func createReminder(messageId: String, createReminderRequest: CreateReminderRequest) async throws -> ReminderResponseData

    func getReplies(parentId: String, limit: Int?, idGte: String?, idGt: String?, idLte: String?, idLt: String?, idAround: String?, sort: [SortParamRequestModel]?) async throws -> GetRepliesResponse

    func queryMessageFlags(payload: QueryMessageFlagsPayload?) async throws -> QueryMessageFlagsResponse

    func muteChannel(muteChannelRequest: MuteChannelRequest) async throws -> MuteChannelResponse

    func unmuteChannel(unmuteChannelRequest: UnmuteChannelRequest) async throws -> UnmuteResponse

    func queryBannedUsers(payload: QueryBannedUsersPayload?) async throws -> QueryBannedUsersResponse

    func queryFutureChannelBans(payload: QueryFutureChannelBansPayload?) async throws -> QueryFutureChannelBansResponse

    func queryReminders(queryRemindersRequest: QueryRemindersRequest) async throws -> QueryRemindersResponse

    func search(payload: SearchPayload?) async throws -> SearchResponse

    func sync(syncRequest: SyncRequest, withInaccessibleCids: Bool?, watch: Bool?) async throws -> SyncResponse

    func queryThreads(queryThreadsRequest: QueryThreadsRequest) async throws -> QueryThreadsResponse

    func getThread(messageId: String, watch: Bool?, replyLimit: Int?, participantLimit: Int?, memberLimit: Int?) async throws -> GetThreadResponse

    func updateThreadPartial(messageId: String, updateThreadPartialRequest: UpdateThreadPartialRequest) async throws -> UpdateThreadPartialResponse

    func unreadCounts() async throws -> WrappedUnreadCountsResponse

    func deleteDevice(id: String) async throws -> Response

    func listDevices() async throws -> ListDevicesResponse

    func createDevice(createDeviceRequest: CreateDeviceRequest) async throws -> Response

    func createGuest(createGuestRequest: CreateGuestRequest) async throws -> CreateGuestResponse

    func longPoll(json: WSAuthMessage?) async throws

    func appeal(appealRequest: AppealRequest) async throws -> AppealResponse

    func getAppeal(id: String) async throws -> GetAppealResponse

    func queryAppeals(queryAppealsRequest: QueryAppealsRequest) async throws -> QueryAppealsResponse

    func ban(banRequest: BanRequest) async throws -> BanResponse

    func upsertConfig(upsertConfigRequest: UpsertConfigRequest) async throws -> UpsertConfigResponse

    func deleteConfig(key: String, team: String?) async throws -> DeleteModerationConfigResponse

    func getConfig(key: String, team: String?) async throws -> GetConfigResponse

    func queryModerationConfigs(queryModerationConfigsRequest: QueryModerationConfigsRequest) async throws -> QueryModerationConfigsResponse

    func flag(flagRequest: FlagRequest) async throws -> FlagResponse

    func mute(muteRequest: MuteRequest) async throws -> MuteResponse

    func queryReviewQueue(queryReviewQueueRequest: QueryReviewQueueRequest) async throws -> QueryReviewQueueResponse

    func submitAction(submitActionRequest: SubmitActionRequest) async throws -> SubmitActionResponse

    func getOG(url: String) async throws -> GetOGResponse

    func createPoll(createPollRequest: CreatePollRequest) async throws -> PollResponse

    func updatePoll(updatePollRequest: UpdatePollRequest) async throws -> PollResponse

    func queryPolls(userId: String?, queryPollsRequest: QueryPollsRequest) async throws -> QueryPollsResponse

    func deletePoll(pollId: String, userId: String?) async throws -> Response

    func getPoll(pollId: String, userId: String?) async throws -> PollResponse

    func updatePollPartial(pollId: String, updatePollPartialRequest: UpdatePollPartialRequest) async throws -> PollResponse

    func createPollOption(pollId: String, createPollOptionRequest: CreatePollOptionRequest) async throws -> PollOptionResponseModel

    func updatePollOption(pollId: String, updatePollOptionRequest: UpdatePollOptionRequestModel) async throws -> PollOptionResponseModel

    func deletePollOption(pollId: String, optionId: String, userId: String?) async throws -> Response

    func getPollOption(pollId: String, optionId: String, userId: String?) async throws -> PollOptionResponseModel

    func queryPollVotes(pollId: String, userId: String?, queryPollVotesRequest: QueryPollVotesRequest) async throws -> PollVotesResponse

    func updatePushNotificationPreferences(upsertPushPreferencesRequest: UpsertPushPreferencesRequest) async throws -> UpsertPushPreferencesResponse

    func deleteFile(url: String?) async throws -> Response

    func uploadFile(fileUploadRequest: FileUploadRequest) async throws -> FileUploadResponse

    func deleteImage(url: String?) async throws -> Response

    func uploadImage(imageUploadRequest: ImageUploadRequest) async throws -> ImageUploadResponse

    func listUserGroups(limit: Int?, idGt: String?, createdAtGt: String?, teamId: String?) async throws -> ListUserGroupsResponse

    func createUserGroup(createUserGroupRequest: CreateUserGroupRequest) async throws -> CreateUserGroupResponse

    func searchUserGroups(query: String, limit: Int?, nameGt: String?, idGt: String?, teamId: String?) async throws -> SearchUserGroupsResponse

    func deleteUserGroup(id: String, teamId: String?) async throws -> Response

    func getUserGroup(id: String, teamId: String?) async throws -> GetUserGroupResponse

    func updateUserGroup(id: String, updateUserGroupRequest: UpdateUserGroupRequest) async throws -> UpdateUserGroupResponse

    func addUserGroupMembers(id: String, addUserGroupMembersRequest: AddUserGroupMembersRequest) async throws -> AddUserGroupMembersResponse

    func removeUserGroupMembers(id: String, removeUserGroupMembersRequest: RemoveUserGroupMembersRequest) async throws -> RemoveUserGroupMembersResponse

    func queryUsers(payload: QueryUsersPayload?) async throws -> QueryUsersResponse

    func updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest) async throws -> UpdateUsersResponse

    func updateUsers(updateUsersRequest: UpdateUsersRequest) async throws -> UpdateUsersResponse

    func getBlockedUsers() async throws -> GetBlockedUsersResponse

    func blockUsers(blockUsersRequest: BlockUsersRequest) async throws -> BlockUsersResponse

    func getUserLiveLocations() async throws -> SharedLocationsResponse

    func updateLiveLocation(updateLiveLocationRequest: UpdateLiveLocationRequest) async throws -> SharedLocationResponse

    func unblockUsers(unblockUsersRequest: UnblockUsersRequest) async throws -> UnblockUsersResponse
}
