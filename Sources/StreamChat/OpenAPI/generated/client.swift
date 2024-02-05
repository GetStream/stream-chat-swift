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

    public func deleteReaction(id: String, type: String, userId: String?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatReactionRemovalResponse, Error>) -> Void) {
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
            let userIdQueryItem = URLQueryItem(name: "user_id", value: userIdValue)
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getReactions(id: String, limit: Int?, offset: Int?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatGetReactionsResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryMessageFlags(payload: StreamChatQueryMessageFlagsRequest?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatQueryMessageFlagsResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/flags/message"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: ["payload": payload]) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateChannel(type: String, id: String, updateChannelRequest: StreamChatUpdateChannelRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUpdateChannelResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteChannel(type: String, id: String, hardDelete: Bool?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatDeleteChannelResponse, Error>) -> Void) {
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
            let hardDeleteQueryItem = URLQueryItem(name: "hard_delete", value: hardDeleteValue)
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: StreamChatUpdateChannelPartialRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUpdateChannelPartialResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getMessage(id: String, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMessageWithPendingMetadataResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateMessage(id: String, updateMessageRequest: StreamChatUpdateMessageRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUpdateMessageResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateMessagePartial(id: String, updateMessagePartialRequest: StreamChatUpdateMessagePartialRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUpdateMessagePartialResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteMessage(id: String, hard: Bool?, deletedBy: String?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
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
            let deletedByQueryItem = URLQueryItem(name: "deleted_by", value: deletedByValue)
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getOrCreateChannel(type: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, requiresConnectionId: Bool, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatChannelStateResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func uploadImage(type: String, id: String, imageUploadRequest: StreamChatImageUploadRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatImageUploadResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteImage(type: String, id: String, url: String?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatFileDeleteResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func stopWatchingChannel(type: String, id: String, channelStopWatchingRequest: StreamChatChannelStopWatchingRequest, requiresConnectionId: Bool, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatStopWatchingResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func markUnread(type: String, id: String, markUnreadRequest: StreamChatMarkUnreadRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func muteUser(muteUserRequest: StreamChatMuteUserRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMuteUserResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sync(syncRequest: StreamChatSyncRequest, withInaccessibleCids: Bool?, watch: Bool?, requiresConnectionId: Bool, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatSyncResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/sync"
        
        var queryParams = [URLQueryItem]()
        
        if let withInaccessibleCids {
            let withInaccessibleCidsValue = String(withInaccessibleCids)
            let withInaccessibleCidsQueryItem = URLQueryItem(name: "with_inaccessible_cids", value: withInaccessibleCidsValue)
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryChannels(queryChannelsRequest: StreamChatQueryChannelsRequest, requiresConnectionId: Bool, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatChannelsResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteChannels(deleteChannelsRequest: StreamChatDeleteChannelsRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatDeleteChannelsResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, requiresConnectionId: Bool, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatChannelStateResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func showChannel(type: String, id: String, showChannelRequest: StreamChatShowChannelRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatShowChannelResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func search(payload: StreamChatSearchRequest?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatSearchResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/search"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: ["payload": payload]) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryUsers(payload: StreamChatQueryUsersRequest?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUsersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/users"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: ["payload": payload]) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateUsers(updateUsersRequest: StreamChatUpdateUsersRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUpdateUsersResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func updateUsersPartial(updateUserPartialRequest: StreamChatUpdateUserPartialRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUpdateUsersResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sendMessage(type: String, id: String, sendMessageRequest: StreamChatSendMessageRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatSendMessageResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getManyMessages(type: String, id: String, ids: [String]?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatGetManyMessagesResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func runMessageAction(id: String, messageActionRequest: StreamChatMessageActionRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sendReaction(id: String, sendReactionRequest: StreamChatSendReactionRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatReactionResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func listDevices(userId: String?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatListDevicesResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/devices"
        
        var queryParams = [URLQueryItem]()
        
        if let userId {
            let userIdValue = String(userId)
            let userIdQueryItem = URLQueryItem(name: "user_id", value: userIdValue)
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func createDevice(createDeviceRequest: StreamChatCreateDeviceRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteDevice(id: String?, userId: String?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
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
            let userIdQueryItem = URLQueryItem(name: "user_id", value: userIdValue)
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func createGuest(guestRequest: StreamChatGuestRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatGuestResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func longPoll(requiresConnectionId: Bool, json: StreamChatConnectRequest?, isRecoveryOperation: Bool = false, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func markRead(type: String, id: String, markReadRequest: StreamChatMarkReadRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMarkReadResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryMembers(payload: StreamChatQueryMembersRequest?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMembersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/members"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: ["payload": payload]) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func uploadFile(type: String, id: String, fileUploadRequest: StreamChatFileUploadRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatFileUploadResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func deleteFile(type: String, id: String, url: String?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatFileDeleteResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func queryBannedUsers(payload: StreamChatQueryBannedUsersRequest?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatQueryBannedUsersResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/query_banned_users"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: ["payload": payload]) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func markChannelsRead(markChannelsReadRequest: StreamChatMarkChannelsReadRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMarkReadResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func sendEvent(type: String, id: String, sendEventRequest: StreamChatSendEventRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatEventResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unmuteUser(unmuteUserRequest: StreamChatUnmuteUserRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUnmuteResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unmuteChannel(unmuteChannelRequest: StreamChatUnmuteChannelRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUnmuteResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unreadCounts(isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatUnreadCountsResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getOG(url: String?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatGetOGResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getApp(isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatGetApplicationResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func truncateChannel(type: String, id: String, truncateChannelRequest: StreamChatTruncateChannelRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatTruncateChannelResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func flag(flagRequest: StreamChatFlagRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatFlagResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func translateMessage(id: String, translateMessageRequest: StreamChatTranslateMessageRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func ban(banRequest: StreamChatBanRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func unban(targetUserId: String?, type: String?, id: String?, createdBy: String?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        let path = "/api/v2/chat/moderation/ban"
        
        var queryParams = [URLQueryItem]()
        
        if let targetUserId {
            let targetUserIdValue = String(targetUserId)
            let targetUserIdQueryItem = URLQueryItem(name: "target_user_id", value: targetUserIdValue)
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
            let createdByQueryItem = URLQueryItem(name: "created_by", value: createdByValue)
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func muteChannel(muteChannelRequest: StreamChatMuteChannelRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatMuteChannelResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func connect(json: StreamChatConnectRequest?, isRecoveryOperation: Bool = false, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func hideChannel(type: String, id: String, hideChannelRequest: StreamChatHideChannelRequest, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatHideChannelResponse, Error>) -> Void) {
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
                self.apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getReplies(parentId: String, idGte: String?, idGt: String?, idLte: String?, idLt: String?, createdAtAfterOrEqual: Date?, createdAtAfter: Date?, createdAtBeforeOrEqual: Date?, createdAtBefore: Date?, idAround: String?, createdAtAround: Date?, isRecoveryOperation: Bool = false, completion: @escaping (Result<StreamChatGetRepliesResponse, Error>) -> Void) {
        var connectionIdRequired: Bool
        connectionIdRequired = false
        var tokenRequired: Bool
        tokenRequired = true
        var path = "/api/v2/chat/messages/{parent_id}/replies"
        
        let parentIdPreEscape = "\(APIHelper.mapValueToPathItem(parentId))"
        let parentIdPostEscape = parentIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "parent_id"), with: parentIdPostEscape, options: .literal, range: nil)
        var queryParams = [URLQueryItem]()
        
        if let idGte {
            let idGteValue = String(idGte)
            let idGteQueryItem = URLQueryItem(name: "id_gte", value: idGteValue)
            queryParams.append(idGteQueryItem)
        }
        if let idGt {
            let idGtValue = String(idGt)
            let idGtQueryItem = URLQueryItem(name: "id_gt", value: idGtValue)
            queryParams.append(idGtQueryItem)
        }
        if let idLte {
            let idLteValue = String(idLte)
            let idLteQueryItem = URLQueryItem(name: "id_lte", value: idLteValue)
            queryParams.append(idLteQueryItem)
        }
        if let idLt {
            let idLtValue = String(idLt)
            let idLtQueryItem = URLQueryItem(name: "id_lt", value: idLtValue)
            queryParams.append(idLtQueryItem)
        }
        if let createdAtAfterOrEqual {
            let createdAtAfterOrEqualValue = formatter.string(from: createdAtAfterOrEqual)
            let createdAtAfterOrEqualQueryItem = URLQueryItem(name: "created_at_after_or_equal", value: createdAtAfterOrEqualValue)
            queryParams.append(createdAtAfterOrEqualQueryItem)
        }
        if let createdAtAfter {
            let createdAtAfterValue = formatter.string(from: createdAtAfter)
            let createdAtAfterQueryItem = URLQueryItem(name: "created_at_after", value: createdAtAfterValue)
            queryParams.append(createdAtAfterQueryItem)
        }
        if let createdAtBeforeOrEqual {
            let createdAtBeforeOrEqualValue = formatter.string(from: createdAtBeforeOrEqual)
            let createdAtBeforeOrEqualQueryItem = URLQueryItem(name: "created_at_before_or_equal", value: createdAtBeforeOrEqualValue)
            queryParams.append(createdAtBeforeOrEqualQueryItem)
        }
        if let createdAtBefore {
            let createdAtBeforeValue = formatter.string(from: createdAtBefore)
            let createdAtBeforeQueryItem = URLQueryItem(name: "created_at_before", value: createdAtBeforeValue)
            queryParams.append(createdAtBeforeQueryItem)
        }
        if let idAround {
            let idAroundValue = String(idAround)
            let idAroundQueryItem = URLQueryItem(name: "id_around", value: idAroundValue)
            queryParams.append(idAroundQueryItem)
        }
        if let createdAtAround {
            let createdAtAroundValue = formatter.string(from: createdAtAround)
            let createdAtAroundQueryItem = URLQueryItem(name: "created_at_around", value: createdAtAroundValue)
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
                apiClient.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
