//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

open class API: DefaultAPIEndpoints, @unchecked Sendable {
    internal var apiClient: APIClient
    internal var basePath: String
    internal var apiKey: APIKey

    init(apiClient: APIClient, basePath: String, apiKey: APIKey) {
        self.apiClient = apiClient
        self.basePath = basePath
        self.apiKey = apiKey
    }

    func makeRequest(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String
    ) throws -> Request {
        let url = URL(string: basePath + uriPath)!
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        var queryParams = queryParams
        queryParams.append(apiKey)
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
        r.body = try JSONEncoder.default.encode(request)
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

    open func deleteChannels(deleteChannelsRequest: StreamChatDeleteChannelsRequest, completion: @escaping (Result<StreamChatDeleteChannelsResponse, Error>) -> Void) {
        let path = "/channels/delete"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: deleteChannelsRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func sendMessage(type: String, id: String, sendMessageRequest: StreamChatSendMessageRequest, completion: @escaping (Result<StreamChatSendMessageResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/message"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: sendMessageRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func markRead(type: String, id: String, markReadRequest: StreamChatMarkReadRequest, completion: @escaping (Result<StreamChatMarkReadResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/read"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: markReadRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func showChannel(type: String, id: String, showChannelRequest: StreamChatShowChannelRequest, completion: @escaping (Result<StreamChatShowChannelResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/show"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: showChannelRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func queryMembers(payload: StreamChatQueryMembersRequest?, completion: @escaping (Result<StreamChatMembersResponse, Error>) -> Void) {
        let path = "/members"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getMessage(id: String, completion: @escaping (Result<StreamChatMessageWithPendingMetadataResponse, Error>) -> Void) {
        var path = "/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func updateMessage(id: String, updateMessageRequest: StreamChatUpdateMessageRequest, completion: @escaping (Result<StreamChatUpdateMessageResponse, Error>) -> Void) {
        var path = "/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: updateMessageRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func updateMessagePartial(id: String, updateMessagePartialRequest: StreamChatUpdateMessagePartialRequest, completion: @escaping (Result<StreamChatUpdateMessagePartialResponse, Error>) -> Void) {
        var path = "/messages/{id}"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "PUT",
                request: updateMessagePartialRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func deleteMessage(id: String, hard: Bool?, deletedBy: String?, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "DELETE"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func translateMessage(id: String, translateMessageRequest: StreamChatTranslateMessageRequest, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
        var path = "/messages/{id}/translate"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: translateMessageRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getOG(url: String?, completion: @escaping (Result<StreamChatGetOGResponse, Error>) -> Void) {
        let path = "/og"
        
        var queryParams = [URLQueryItem]()
        
        if let url {
            let urlValue = String(url)
            let urlQueryItem = URLQueryItem(name: "url", value: urlValue)
            queryParams.append(urlQueryItem)
        }
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func search(payload: StreamChatSearchRequest?, completion: @escaping (Result<StreamChatSearchResponse, Error>) -> Void) {
        let path = "/search"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func unreadCounts(completion: @escaping (Result<StreamChatUnreadCountsResponse, Error>) -> Void) {
        let path = "/unread"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getApp(completion: @escaping (Result<StreamChatGetApplicationResponse, Error>) -> Void) {
        let path = "/app"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func updateChannel(type: String, id: String, updateChannelRequest: StreamChatUpdateChannelRequest, completion: @escaping (Result<StreamChatUpdateChannelResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: updateChannelRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func deleteChannel(type: String, id: String, hardDelete: Bool?, completion: @escaping (Result<StreamChatDeleteChannelResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "DELETE"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func updateChannelPartial(type: String, id: String, updateChannelPartialRequest: StreamChatUpdateChannelPartialRequest, completion: @escaping (Result<StreamChatUpdateChannelPartialResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "PATCH",
                request: updateChannelPartialRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func uploadFile(type: String, id: String, fileUploadRequest: StreamChatFileUploadRequest, completion: @escaping (Result<StreamChatFileUploadResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/file"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: fileUploadRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func deleteFile(type: String, id: String, url: String?, completion: @escaping (Result<StreamChatFileDeleteResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "DELETE"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getOrCreateChannel(type: String, id: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, connectionId: String?, completion: @escaping (Result<StreamChatChannelStateResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: channelGetOrCreateRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func muteChannel(muteChannelRequest: StreamChatMuteChannelRequest, completion: @escaping (Result<StreamChatMuteChannelResponse, Error>) -> Void) {
        let path = "/moderation/mute/channel"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: muteChannelRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func unmuteChannel(unmuteChannelRequest: StreamChatUnmuteChannelRequest, completion: @escaping (Result<StreamChatUnmuteResponse, Error>) -> Void) {
        let path = "/moderation/unmute/channel"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: unmuteChannelRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func sync(syncRequest: StreamChatSyncRequest, withInaccessibleCids: Bool?, watch: Bool?, connectionId: String?, completion: @escaping (Result<StreamChatSyncResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: syncRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func uploadImage(type: String, id: String, imageUploadRequest: StreamChatImageUploadRequest, completion: @escaping (Result<StreamChatImageUploadResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/image"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: imageUploadRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func deleteImage(type: String, id: String, url: String?, completion: @escaping (Result<StreamChatFileDeleteResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "DELETE"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getManyMessages(type: String, id: String, ids: [String]?, completion: @escaping (Result<StreamChatGetManyMessagesResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func markUnread(type: String, id: String, markUnreadRequest: StreamChatMarkUnreadRequest, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/unread"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: markUnreadRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func longPoll(connectionId: String?, json: StreamChatConnectRequest?, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
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
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func flag(flagRequest: StreamChatFlagRequest, completion: @escaping (Result<StreamChatFlagResponse, Error>) -> Void) {
        let path = "/moderation/flag"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: flagRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func unmuteUser(unmuteUserRequest: StreamChatUnmuteUserRequest, completion: @escaping (Result<StreamChatUnmuteResponse, Error>) -> Void) {
        let path = "/moderation/unmute"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: unmuteUserRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func queryBannedUsers(payload: StreamChatQueryBannedUsersRequest?, completion: @escaping (Result<StreamChatQueryBannedUsersResponse, Error>) -> Void) {
        let path = "/query_banned_users"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getCallToken(callId: String, getCallTokenRequest: StreamChatGetCallTokenRequest, completion: @escaping (Result<StreamChatGetCallTokenResponse, Error>) -> Void) {
        var path = "/calls/{call_id}"
        
        let callIdPreEscape = "\(APIHelper.mapValueToPathItem(callId))"
        let callIdPostEscape = callIdPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "callId"), with: callIdPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: getCallTokenRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func queryChannels(queryChannelsRequest: StreamChatQueryChannelsRequest, connectionId: String?, completion: @escaping (Result<StreamChatChannelsResponse, Error>) -> Void) {
        let path = "/channels"
        
        var queryParams = [URLQueryItem]()
        
        if let connectionId {
            let connectionIdValue = String(connectionId)
            let connectionIdQueryItem = URLQueryItem(name: "connectionId", value: connectionIdValue)
            queryParams.append(connectionIdQueryItem)
        }
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: queryChannelsRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func stopWatchingChannel(type: String, id: String, channelStopWatchingRequest: StreamChatChannelStopWatchingRequest, connectionId: String?, completion: @escaping (Result<StreamChatStopWatchingResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: channelStopWatchingRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func runMessageAction(id: String, messageActionRequest: StreamChatMessageActionRequest, completion: @escaping (Result<StreamChatMessageResponse, Error>) -> Void) {
        var path = "/messages/{id}/action"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: messageActionRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getCallToken(getCallTokenRequest: StreamChatGetCallTokenRequest, completion: @escaping (Result<StreamChatGetCallTokenResponse, Error>) -> Void) {
        let path = "/calls"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: getCallTokenRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func truncateChannel(type: String, id: String, truncateChannelRequest: StreamChatTruncateChannelRequest, completion: @escaping (Result<StreamChatTruncateChannelResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/truncate"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: truncateChannelRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getReactions(id: String, limit: Int?, offset: Int?, completion: @escaping (Result<StreamChatGetReactionsResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getReplies(parentId: String, idGte: String?, idGt: String?, idLte: String?, idLt: String?, createdAtAfterOrEqual: String?, createdAtAfter: String?, createdAtBeforeOrEqual: String?, createdAtBefore: String?, idAround: String?, createdAtAround: String?, completion: @escaping (Result<StreamChatGetRepliesResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func getOrCreateChannel(type: String, channelGetOrCreateRequest: StreamChatChannelGetOrCreateRequest, connectionId: String?, completion: @escaping (Result<StreamChatChannelStateResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: channelGetOrCreateRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func hideChannel(type: String, id: String, hideChannelRequest: StreamChatHideChannelRequest, completion: @escaping (Result<StreamChatHideChannelResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/hide"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: hideChannelRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func deleteReaction(id: String, type: String, userId: String?, completion: @escaping (Result<StreamChatReactionRemovalResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "DELETE"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func markChannelsRead(markChannelsReadRequest: StreamChatMarkChannelsReadRequest, completion: @escaping (Result<StreamChatMarkReadResponse, Error>) -> Void) {
        let path = "/channels/read"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: markChannelsReadRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func createGuest(guestRequest: StreamChatGuestRequest, completion: @escaping (Result<StreamChatGuestResponse, Error>) -> Void) {
        let path = "/guest"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: guestRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func ban(banRequest: StreamChatBanRequest, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
        let path = "/moderation/ban"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: banRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func unban(targetUserId: String?, type: String?, id: String?, createdBy: String?, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "DELETE"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func queryUsers(payload: StreamChatQueryUsersRequest?, completion: @escaping (Result<StreamChatUsersResponse, Error>) -> Void) {
        let path = "/users"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func updateUsers(updateUsersRequest: StreamChatUpdateUsersRequest, completion: @escaping (Result<StreamChatUpdateUsersResponse, Error>) -> Void) {
        let path = "/users"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: updateUsersRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func updateUsersPartial(updateUserPartialRequest: StreamChatUpdateUserPartialRequest, completion: @escaping (Result<StreamChatUpdateUsersResponse, Error>) -> Void) {
        let path = "/users"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "PATCH",
                request: updateUserPartialRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func createCall(type: String, id: String, createCallRequest: StreamChatCreateCallRequest, completion: @escaping (Result<StreamChatCreateCallResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/call"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: createCallRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func sendEvent(type: String, id: String, sendEventRequest: StreamChatSendEventRequest, completion: @escaping (Result<StreamChatEventResponse, Error>) -> Void) {
        var path = "/channels/{type}/{id}/event"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: sendEventRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func connect(json: StreamChatConnectRequest?, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let path = "/connect"
        
        var queryParams = [URLQueryItem]()
        
        if let json, let jsonQueryParams = try? encodeJSONToQueryItems(data: json) {
            queryParams.append(contentsOf: jsonQueryParams)
        }
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func listDevices(userId: String?, completion: @escaping (Result<StreamChatListDevicesResponse, Error>) -> Void) {
        let path = "/devices"
        
        var queryParams = [URLQueryItem]()
        
        if let userId {
            let userIdValue = String(userId)
            let userIdQueryItem = URLQueryItem(name: "userId", value: userIdValue)
            queryParams.append(userIdQueryItem)
        }
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func createDevice(createDeviceRequest: StreamChatCreateDeviceRequest, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let path = "/devices"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: createDeviceRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func deleteDevice(id: String?, userId: String?, completion: @escaping (Result<StreamChatResponse, Error>) -> Void) {
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
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "DELETE"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func sendReaction(id: String, sendReactionRequest: StreamChatSendReactionRequest, completion: @escaping (Result<StreamChatReactionResponse, Error>) -> Void) {
        var path = "/messages/{id}/reaction"
        
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: sendReactionRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func queryMessageFlags(payload: StreamChatQueryMessageFlagsRequest?, completion: @escaping (Result<StreamChatQueryMessageFlagsResponse, Error>) -> Void) {
        let path = "/moderation/flags/message"
        
        var queryParams = [URLQueryItem]()
        
        if let payload, let payloadQueryParams = try? encodeJSONToQueryItems(data: payload) {
            queryParams.append(contentsOf: payloadQueryParams)
        }
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "GET"
            )
            
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    open func muteUser(muteUserRequest: StreamChatMuteUserRequest, completion: @escaping (Result<StreamChatMuteUserResponse, Error>) -> Void) {
        let path = "/moderation/mute"
        
        let queryParams = [URLQueryItem]()
        
        do {
            let request = try makeRequest(
                uriPath: path,
                queryParams: queryParams,
                httpMethod: "POST",
                request: muteUserRequest
            )
            let urlRequest = try request.urlRequest()
            apiClient.request(urlRequest, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}
