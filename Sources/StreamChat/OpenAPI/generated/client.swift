//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class API: DefaultAPIEndpoints {
    internal var apiClient: APIClient
    internal var encoder: RequestEncoder
    internal var basePath: String
    internal var apiKey: APIKey

    let formatter = ISO8601DateFormatter()

    init(apiClient: APIClient, encoder: RequestEncoder, basePath: String, apiKey: APIKey) {
        self.apiClient = apiClient
        self.encoder = encoder
        self.basePath = basePath
        self.apiKey = apiKey
    }

    func makeRequest(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String,
        requiresConnectionId: Bool = false,
        requiresToken: Bool = true,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        let url = URL(string: basePath + uriPath)!
        let request = Request(
            url: url,
            method: .init(stringValue: httpMethod),
            queryParams: queryParams,
            headers: ["Content-Type": "application/json"]
        )
        guard let urlRequest = try? request.urlRequest() else {
            completion(.failure(ClientError.Unexpected()))
            return
        }
        encoder.encode(
            request: urlRequest,
            requiresConnectionId: requiresConnectionId,
            requiresToken: requiresToken,
            completion: completion
        )
    }

    func makeRequest<T: Encodable>(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String,
        requiresConnectionId: Bool = false,
        requiresToken: Bool = true,
        request: T,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        makeRequest(
            uriPath: uriPath,
            queryParams: queryParams,
            httpMethod: httpMethod,
            requiresConnectionId: requiresConnectionId,
            requiresToken: requiresToken
        ) { result in
            switch result {
            case var .success(urlRequest):
                if let body = try? JSONEncoder.stream.encode(request) {
                    urlRequest.httpBody = body
                    completion(.success(urlRequest))
                } else {
                    completion(.failure(ClientError.Unknown()))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
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

    public func sendReaction(id: String, sendReactionRequest: StreamChatSendReactionRequest, completion: @escaping (Result<StreamChatReactionResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}/reaction"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: sendReactionRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func translateMessage(id: String, translateMessageRequest: StreamChatTranslateMessageRequest, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}/translate"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: translateMessageRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func goLive(type: String, id: String, goLiveRequest: StreamChatGoLiveRequest, completion: @escaping (Result<StreamChatGoLiveResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/go_live"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: goLiveRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryCalls(queryCallsRequest: StreamChatQueryCallsRequest, requiresConnectionId: Bool, completion: @escaping (Result<StreamChatQueryCallsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/video/calls"
        
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: queryCallsRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getEdges(completion: @escaping (Result<StreamChatGetEdgesResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/video/edges"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func stopWatchingChannel(type: String, id: String, channelStopWatchingRequest: StreamChatChannelStopWatchingRequest, requiresConnectionId: Bool, completion: @escaping (Result<StreamChatStopWatchingResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/stop-watching"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: channelStopWatchingRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func runMessageAction(id: String, messageActionRequest: StreamChatMessageActionRequest, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}/action"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: messageActionRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func stopHLSBroadcasting(type: String, id: String, completion: @escaping (Result<StreamChatStopHLSBroadcastingResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/stop_broadcasting"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func truncateChannel(type: String, id: String, truncateChannelRequest: StreamChatTruncateChannelRequest, completion: @escaping (Result<StreamChatTruncateChannelResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/truncate"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: truncateChannelRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getMessage(id: String, completion: @escaping (Result<StreamChatMessageWithPendingMetadataResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateMessage(id: String, updateMessageRequest: StreamChatUpdateMessageRequest, completion: @escaping (Result<StreamChatUpdateMessageResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateMessageRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateMessagePartial(id: String, updateMessagePartialRequest: StreamChatUpdateMessagePartialRequest, completion: @escaping (Result<StreamChatUpdateMessagePartialResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "PUT",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateMessagePartialRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteMessage(id: String, hard: Bool?, deletedBy: String?, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getReactions(id: String, limit: Int?, offset: Int?, completion: @escaping (Result<StreamChatGetReactionsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}/reactions"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func rejectCall(type: String, id: String, completion: @escaping (Result<StreamChatRejectCallResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/reject"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getApp(completion: @escaping (Result<StreamChatGetApplicationResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/app"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func muteUsers(type: String, id: String, muteUsersRequest: StreamChatMuteUsersRequest, completion: @escaping (Result<StreamChatMuteUsersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/mute_users"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: muteUsersRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func startTranscription(type: String, id: String, completion: @escaping (Result<StreamChatStartTranscriptionResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/start_transcription"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func videoUnpin(type: String, id: String, unpinRequest: StreamChatUnpinRequest, completion: @escaping (Result<StreamChatUnpinResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/unpin"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: unpinRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func showChannel(type: String, id: String, showChannelRequest: StreamChatShowChannelRequest, completion: @escaping (Result<StreamChatShowChannelResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/show"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: showChannelRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unmuteChannel(unmuteChannelRequest: StreamChatUnmuteChannelRequest, completion: @escaping (Result<StreamChatUnmuteResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/unmute/channel"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: unmuteChannelRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryMembers(queryMembersRequest1: StreamChatQueryMembersRequest1, completion: @escaping (Result<StreamChatQueryMembersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/video/call/members"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: queryMembersRequest1
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func joinCall(type: String, id: String, joinCallRequest: StreamChatJoinCallRequest, requiresConnectionId: Bool, completion: @escaping (Result<StreamChatJoinCallResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/join"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: joinCallRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getManyMessages(type: String, id: String, ids: [String]?, completion: @escaping (Result<StreamChatGetManyMessagesResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/messages"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, requiresConnectionId: Bool, completion: @escaping (Result<StreamChatChannelStateResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/query"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: channelGetOrCreateRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateCallMembers(type: String, id: String, updateCallMembersRequest: StreamChatUpdateCallMembersRequest, completion: @escaping (Result<StreamChatUpdateCallMembersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/members"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateCallMembersRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func videoPin(type: String, id: String, pinRequest: StreamChatPinRequest, completion: @escaping (Result<StreamChatPinResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/pin"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: pinRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func markChannelsRead(markChannelsReadRequest: StreamChatMarkChannelsReadRequest, completion: @escaping (Result<StreamChatMarkReadResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/channels/read"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: markChannelsReadRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryMessageFlags(payload: StreamChatQueryMessageFlagsRequest?, completion: @escaping (Result<StreamChatQueryMessageFlagsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/flags/message"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unmuteUser(unmuteUserRequest: StreamChatUnmuteUserRequest, completion: @escaping (Result<StreamChatUnmuteResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/unmute"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: unmuteUserRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func startHLSBroadcasting(type: String, id: String, completion: @escaping (Result<StreamChatStartHLSBroadcastingResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/start_broadcasting"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sendMessage(type: String, id: String, sendMessageRequest: StreamChatSendMessageRequest, completion: @escaping (Result<StreamChatSendMessageResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/message"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: sendMessageRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func markUnread(type: String, id: String, markUnreadRequest: StreamChatMarkUnreadRequest, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/unread"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: markUnreadRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unreadCounts(completion: @escaping (Result<StreamChatUnreadCountsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/unread"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func acceptCall(type: String, id: String, completion: @escaping (Result<StreamChatAcceptCallResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/accept"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func startRecording(type: String, id: String, completion: @escaping (Result<StreamChatStartRecordingResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/start_recording"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func stopLive(type: String, id: String, completion: @escaping (Result<StreamChatStopLiveResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/stop_live"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func markRead(type: String, id: String, markReadRequest: StreamChatMarkReadRequest, completion: @escaping (Result<StreamChatMarkReadResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/read"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: markReadRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func ban(banRequest: StreamChatBanRequest, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/ban"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: banRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unban(targetUserId: String?, type: String?, id: String?, createdBy: String?, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/ban"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func longPoll(requiresConnectionId: Bool, json: StreamChatConnectRequest?, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/longpoll"
        
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        if let json, let jsonQueryParams = try? encodeJSONToQueryItems(data: json) {
            queryParams.append(contentsOf: jsonQueryParams)
        }
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func requestPermission(type: String, id: String, requestPermissionRequest: StreamChatRequestPermissionRequest, completion: @escaping (Result<StreamChatRequestPermissionResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/request_permission"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: requestPermissionRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteReaction(id: String, type: String, userId: String?, completion: @escaping (Result<StreamChatReactionRemovalResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{id}/reaction/{type}"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func stopTranscription(type: String, id: String, completion: @escaping (Result<StreamChatStopTranscriptionResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/stop_transcription"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateUserPermissions(type: String, id: String, updateUserPermissionsRequest: StreamChatUpdateUserPermissionsRequest, completion: @escaping (Result<StreamChatUpdateUserPermissionsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/user_permissions"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateUserPermissionsRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteChannels(deleteChannelsRequest: StreamChatDeleteChannelsRequest, completion: @escaping (Result<StreamChatDeleteChannelsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/channels/delete"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: deleteChannelsRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getReplies(parentId: String, idGte: String?, idGt: String?, idLte: String?, idLt: String?, createdAtAfterOrEqual: Date?, createdAtAfter: Date?, createdAtBeforeOrEqual: Date?, createdAtBefore: Date?, idAround: String?, createdAtAround: Date?, completion: @escaping (Result<StreamChatGetRepliesResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{parent_id}/replies"
        
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
            let createdAtAfterOrEqualValue = formatter.string(from: createdAtAfterOrEqual)
            let createdAtAfterOrEqualQueryItem = URLQueryItem(name: "createdAtAfterOrEqual", value: createdAtAfterOrEqualValue)
            queryParams.append(createdAtAfterOrEqualQueryItem)
        }
        if let createdAtAfter {
            let createdAtAfterValue = formatter.string(from: createdAtAfter)
            let createdAtAfterQueryItem = URLQueryItem(name: "createdAtAfter", value: createdAtAfterValue)
            queryParams.append(createdAtAfterQueryItem)
        }
        if let createdAtBeforeOrEqual {
            let createdAtBeforeOrEqualValue = formatter.string(from: createdAtBeforeOrEqual)
            let createdAtBeforeOrEqualQueryItem = URLQueryItem(name: "createdAtBeforeOrEqual", value: createdAtBeforeOrEqualValue)
            queryParams.append(createdAtBeforeOrEqualQueryItem)
        }
        if let createdAtBefore {
            let createdAtBeforeValue = formatter.string(from: createdAtBefore)
            let createdAtBeforeQueryItem = URLQueryItem(name: "createdAtBefore", value: createdAtBeforeValue)
            queryParams.append(createdAtBeforeQueryItem)
        }
        if let idAround {
            let idAroundValue = String(idAround)
            let idAroundQueryItem = URLQueryItem(name: "idAround", value: idAroundValue)
            queryParams.append(idAroundQueryItem)
        }
        if let createdAtAround {
            let createdAtAroundValue = formatter.string(from: createdAtAround)
            let createdAtAroundQueryItem = URLQueryItem(name: "createdAtAround", value: createdAtAroundValue)
            queryParams.append(createdAtAroundQueryItem)
        }
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func stopRecording(type: String, id: String, completion: @escaping (Result<StreamChatStopRecordingResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/stop_recording"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryMembers(payload: StreamChatQueryMembersRequest?, completion: @escaping (Result<StreamChatMembersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/members"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryBannedUsers(payload: StreamChatQueryBannedUsersRequest?, completion: @escaping (Result<StreamChatQueryBannedUsersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/query_banned_users"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getOG(url: String?, completion: @escaping (Result<StreamChatGetOGResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/og"
        
        var queryParams = [URLQueryItem]()
        
        if let url {
            let urlValue = String(url)
            let urlQueryItem = URLQueryItem(name: "url", value: urlValue)
            queryParams.append(urlQueryItem)
        }
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryUsers(payload: StreamChatQueryUsersRequest?, completion: @escaping (Result<StreamChatUsersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/users"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateUsers(updateUsersRequest: StreamChatUpdateUsersRequest, completion: @escaping (Result<StreamChatUpdateUsersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/users"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateUsersRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateUsersPartial(updateUserPartialRequest: StreamChatUpdateUserPartialRequest, completion: @escaping (Result<StreamChatUpdateUsersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/users"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "PATCH",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateUserPartialRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func listRecordings(type: String, id: String, completion: @escaping (Result<StreamChatListRecordingsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/recordings"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func muteUser(muteUserRequest: StreamChatMuteUserRequest, completion: @escaping (Result<StreamChatMuteUserResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/mute"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: muteUserRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func hideChannel(type: String, id: String, hideChannelRequest: StreamChatHideChannelRequest, completion: @escaping (Result<StreamChatHideChannelResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/hide"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: hideChannelRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func uploadImage(type: String, id: String, imageUploadRequest: StreamChatImageUploadRequest, completion: @escaping (Result<StreamChatImageUploadResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/image"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: imageUploadRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteImage(type: String, id: String, url: String?, completion: @escaping (Result<StreamChatFileDeleteResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/image"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sync(syncRequest: StreamChatSyncRequest, withInaccessibleCids: Bool?, watch: Bool?, requiresConnectionId: Bool, completion: @escaping (Result<StreamChatSyncResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/sync"
        
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
        connectionIdRequired = requiresConnectionId
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: syncRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func uploadFile(type: String, id: String, fileUploadRequest: StreamChatFileUploadRequest, completion: @escaping (Result<StreamChatFileUploadResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/file"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: fileUploadRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteFile(type: String, id: String, url: String?, completion: @escaping (Result<StreamChatFileDeleteResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/file"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sendEvent(type: String, id: String, sendEventRequest: StreamChatSendEventRequest, completion: @escaping (Result<StreamChatEventResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}/event"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: sendEventRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func flag(flagRequest: StreamChatFlagRequest, completion: @escaping (Result<StreamChatFlagResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/flag"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: flagRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func muteChannel(muteChannelRequest: StreamChatMuteChannelRequest, completion: @escaping (Result<StreamChatMuteChannelResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/mute/channel"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: muteChannelRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func search(payload: StreamChatSearchRequest?, completion: @escaping (Result<StreamChatSearchResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/search"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func connect(json: StreamChatConnectRequest?, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/connect"
        
        var queryParams = [URLQueryItem]()
        
        if let json, let jsonQueryParams = try? encodeJSONToQueryItems(data: json) {
            queryParams.append(contentsOf: jsonQueryParams)
        }
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getCall(type: String, id: String, requiresConnectionId: Bool, membersLimit: Int?, ring: Bool?, notify: Bool?, completion: @escaping (Result<StreamChatGetCallResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        if let membersLimit {
            let membersLimitValue = String(membersLimit)
            let membersLimitQueryItem = URLQueryItem(name: "membersLimit", value: membersLimitValue)
            queryParams.append(membersLimitQueryItem)
        }
        if let ring {
            let ringValue = String(ring)
            let ringQueryItem = URLQueryItem(name: "ring", value: ringValue)
            queryParams.append(ringQueryItem)
        }
        if let notify {
            let notifyValue = String(notify)
            let notifyQueryItem = URLQueryItem(name: "notify", value: notifyValue)
            queryParams.append(notifyQueryItem)
        }
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getOrCreateCall(type: String, id: String, getOrCreateCallRequest: StreamChatGetOrCreateCallRequest, requiresConnectionId: Bool, completion: @escaping (Result<StreamChatGetOrCreateCallResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: getOrCreateCallRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateCall(type: String, id: String, updateCallRequest: StreamChatUpdateCallRequest, completion: @escaping (Result<StreamChatUpdateCallResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "PATCH",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateCallRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sendEvent(type: String, id: String, sendEventRequest: StreamChatSendEventRequest, completion: @escaping (Result<StreamChatSendEventResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/event"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: sendEventRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getOrCreateChannel(type: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, requiresConnectionId: Bool, completion: @escaping (Result<StreamChatChannelStateResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/query"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: channelGetOrCreateRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sendVideoReaction(type: String, id: String, sendReactionRequest: StreamChatSendReactionRequest, completion: @escaping (Result<StreamChatSendReactionResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/reaction"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: sendReactionRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateChannel(type: String, id: String, updateChannelRequest: StreamChatUpdateChannelRequest, completion: @escaping (Result<StreamChatUpdateChannelResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateChannelRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteChannel(type: String, id: String, hardDelete: Bool?, completion: @escaping (Result<StreamChatDeleteChannelResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: StreamChatUpdateChannelPartialRequest, completion: @escaping (Result<StreamChatUpdateChannelPartialResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/channels/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "PATCH",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: updateChannelPartialRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func listDevices(userId: String?, completion: @escaping (Result<StreamChatListDevicesResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/devices"
        
        var queryParams = [URLQueryItem]()
        
        if let userId {
            let userIdValue = String(userId)
            let userIdQueryItem = URLQueryItem(name: "userId", value: userIdValue)
            queryParams.append(userIdQueryItem)
        }
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "GET",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func createDevice(createDeviceRequest: StreamChatCreateDeviceRequest, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/devices"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: createDeviceRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteDevice(id: String?, userId: String?, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/devices"
        
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
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "DELETE",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func createGuest(guestRequest: StreamChatGuestRequest, completion: @escaping (Result<StreamChatGuestResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/guest"
        
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        tokenRequired = false
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: guestRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func blockUser(type: String, id: String, blockUserRequest: StreamChatBlockUserRequest, completion: @escaping (Result<StreamChatBlockUserResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/block"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: blockUserRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryChannels(queryChannelsRequest: StreamChatQueryChannelsRequest, requiresConnectionId: Bool, completion: @escaping (Result<StreamChatChannelsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/channels"
        
        var queryParams = [URLQueryItem]()
        
        connectionIdRequired = requiresConnectionId
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: queryChannelsRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unblockUser(type: String, id: String, unblockUserRequest: StreamChatUnblockUserRequest, completion: @escaping (Result<StreamChatUnblockUserResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/unblock"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired,
            request: unblockUserRequest
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                self.apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func endCall(type: String, id: String, completion: @escaping (Result<StreamChatEndCallResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/video/call/{type}/{id}/mark_ended"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        makeRequest(
            uriPath: path,
            queryParams: queryParams,
            httpMethod: "POST",
            requiresConnectionId: connectionIdRequired,
            requiresToken: tokenRequired
        ) { [weak self] result in
            guard let self else {
                completion(.failure(ClientError.Unknown()))
                return
            }
            switch result {
            case let .success(request):
                apiClient.request(request, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}