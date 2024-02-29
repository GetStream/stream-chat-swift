//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class API_Tests: XCTestCase {
    var encoder: RequestEncoder!
    var baseURL: URL!
    var apiKey: APIKey!
    fileprivate var connectionDetailsProvider: ConnectionDetailsProviderDelegate_Spy!

    override func setUp() {
        super.setUp()

        apiKey = APIKey("")
        baseURL = .unique()
        encoder = DefaultRequestEncoder(baseURL: baseURL, apiKey: apiKey)

        connectionDetailsProvider = ConnectionDetailsProviderDelegate_Spy()
        encoder.connectionDetailsProviderDelegate = connectionDetailsProvider

        VirtualTimeTimer.time = VirtualTime()
    }

    func test_apiMakeRequest_default() {
        // Given
        let api = API.mock(with: APIClient_Spy(), encoder: encoder)
        let expectation = expectation(description: "request")
        
        // When
        var result: Result<URLRequest, Error>?
        api.makeRequest(
            uriPath: "/messages",
            httpMethod: "POST",
            requiresToken: false
        ) {
            result = $0
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        let request = result?.value
        let headers = request?.allHTTPHeaderFields
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(headers?["Content-Type"], "application/json")
        XCTAssertEqual(headers?["Stream-Auth-Type"], "anonymous")
    }
    
    func test_apiMakeRequest_tokenRequired() throws {
        // Given
        let api = API.mock(with: APIClient_Spy(), encoder: encoder)
        
        // When
        
        // Simulate provided token
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // Encode the request and wait for the result
        let request = try waitFor {
            api.makeRequest(
                uriPath: "/messages",
                httpMethod: "POST",
                requiresToken: true,
                completion: $0
            )
        }.get()
        
        // Then
        let headers = request.allHTTPHeaderFields
        XCTAssertNotNil(request)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(headers?["Content-Type"], "application/json")
        XCTAssertEqual(headers?["Stream-Auth-Type"], "jwt")
        XCTAssertEqual(headers?["Authorization"], token.rawValue)
    }
    
    func test_apiMakeRequest_connectionIdRequired() throws {
        // Given
        let api = API.mock(with: APIClient_Spy(), encoder: encoder)
        
        // When
        
        // Simulate provided token
        let connectionId = ConnectionId.unique
        connectionDetailsProvider.provideConnectionIdResult = .success(connectionId)

        // Encode the request and wait for the result
        let request = try waitFor {
            api.makeRequest(
                uriPath: "/messages",
                httpMethod: "POST",
                requiresConnectionId: true,
                requiresToken: false,
                completion: $0
            )
        }.get()
        
        // Then
        let headers = request.allHTTPHeaderFields
        XCTAssertNotNil(request)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.queryItems[0], .init(name: "connection_id", value: connectionId))
        XCTAssertEqual(headers?["Content-Type"], "application/json")
        XCTAssertEqual(headers?["Stream-Auth-Type"], "anonymous")
    }
    
    func test_apiMakeRequest_body() throws {
        // Given
        let api = API.mock(with: APIClient_Spy(), encoder: encoder)
        let messageId = String.unique
        let messageRequest = MessageRequest(attachments: [], id: messageId)
        
        // When
        let request = try waitFor {
            api.makeRequest(
                uriPath: "/messages",
                httpMethod: "POST",
                requiresToken: false,
                request: messageRequest,
                completion: $0
            )
        }.get()
        
        // Then
        let headers = request.allHTTPHeaderFields
        let body = request.httpBody
        XCTAssertNotNil(request)
        XCTAssertNotNil(body)
        let bodyModel = try JSONDecoder.stream.decode(MessageRequest.self, from: body!)
        XCTAssertEqual(bodyModel.id, messageId)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(headers?["Content-Type"], "application/json")
        XCTAssertEqual(headers?["Stream-Auth-Type"], "anonymous")
    }
    
    public func test_apiRequest_markUnread() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.markUnread(type: "type", id: "id", markUnreadRequest: .init(messageId: .unique), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<Response, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/unread"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(MarkUnreadRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_muteChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.muteChannel(muteChannelRequest: .init(channelCids: []), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MuteChannelResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/moderation/mute/channel"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(MuteChannelRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_search() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.search(payload: .init(.init(filterConditions: [:])), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<SearchResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/search"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let filter = URLQueryItem(name: "payload", value: "{\"filter_conditions\":{}}")
        queryParams.append(filter)

        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_unreadCounts() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.unreadCounts(completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UnreadCountsResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/unread"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_listDevices() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.listDevices(userId: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<ListDevicesResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/devices"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let userIdQueryItem = URLQueryItem(name: "user_id", value: "")
        queryParams.append(userIdQueryItem)

        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_createDevice() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.createDevice(createDeviceRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<EmptyResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/devices"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(CreateDeviceRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_deleteDevice() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.deleteDevice(id: .init(), userId: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<Response, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/devices"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let idQueryItem = URLQueryItem(name: "id", value: "")
        queryParams.append(idQueryItem)
        
        let userIdQueryItem = URLQueryItem(name: "user_id", value: "")
        queryParams.append(userIdQueryItem)

        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
                
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }

    public func test_apiRequest_stopWatchingChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        let connectionId = String.unique
        connectionDetailsProvider.provideConnectionIdResult = .success(connectionId)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.stopWatchingChannel(type: "type", id: "id", channelStopWatchingRequest: .init(), requiresConnectionId: true, completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<StopWatchingResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/stop-watching"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        let connectionIdQueryItem = URLQueryItem(name: "connection_id", value: connectionId)
        queryParams.append(connectionIdQueryItem)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(ChannelStopWatchingRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_queryMembers() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.queryMembers(payload: .init(.init(type: "test", filterConditions: [:])), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MembersResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/members"
        
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_flag() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.flag(flagRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<FlagResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/moderation/flag"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(FlagRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_hideChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.hideChannel(type: "type", id: "id", hideChannelRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<HideChannelResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/hide"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(HideChannelRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_getReactions() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.getReactions(id: "id", limit: .init(), offset: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<GetReactionsResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}/reactions"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_muteUser() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.muteUser(muteUserRequest: .init(targetIds: []), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MuteUserResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/moderation/mute"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(MuteUserRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_longPoll() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.longPoll(requiresConnectionId: true, json: .init(.init(userDetails: .dummy(userId: .unique))), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<EmptyResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/longpoll"
        
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_getApp() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.getApp(completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<GetApplicationResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/app"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_markChannelsRead() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.markChannelsRead(markChannelsReadRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MarkReadResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/channels/read"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(MarkChannelsReadRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_sendEvent() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.sendEvent(type: "type", id: "id", sendEventRequest: .init(event: .init(type: "test")), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<EventResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/event"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(SendEventRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_sendMessage() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.sendMessage(type: "type", id: "id", sendMessageRequest: .init(message: .init(attachments: [])), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<SendMessageResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/message"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(SendMessageRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_getManyMessages() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.getManyMessages(type: "type", id: "id", ids: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<GetManyMessagesResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/messages"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let idsValue = [""].joined(separator: ",")
        let idsQueryItem = URLQueryItem(name: "ids", value: idsValue)
        queryParams.append(idsQueryItem)
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_sync() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.sync(syncRequest: .init(lastSyncAt: .unique), withInaccessibleCids: false, watch: true, requiresConnectionId: true) { _ in
            expectation.fulfill()
        }

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<SyncResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/sync"
        
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(SyncRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_getOG() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.getOG(url: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<GetOGResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/og"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let urlValue = String("")
        let urlQueryItem = URLQueryItem(name: "url", value: urlValue)
        queryParams.append(urlQueryItem)
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_deleteChannels() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.deleteChannels(deleteChannelsRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<DeleteChannelsResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/channels/delete"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(DeleteChannelsRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_uploadImage() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.uploadImage(type: "type", id: "id", imageUploadRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<ImageUploadResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/image"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(ImageUploadRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_deleteImage() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.deleteImage(type: "type", id: "id", url: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<FileDeleteResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/image"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let urlValue = String("")
        let urlQueryItem = URLQueryItem(name: "url", value: urlValue)
        queryParams.append(urlQueryItem)
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }

    public func test_apiRequest_translateMessage() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.translateMessage(id: "id", translateMessageRequest: .init(language: "en"), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MessageResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}/translate"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(TranslateMessageRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_getReplies() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.getReplies(parentId: "parentId", idGte: .init(), idGt: .init(), idLte: .init(), idLt: .init(), createdAtAfterOrEqual: .init(), createdAtAfter: .init(), createdAtBeforeOrEqual: .init(), createdAtBefore: .init(), idAround: .init(), createdAtAround: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<GetRepliesResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{parent_id}/replies"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "parent_id"), with: "parentId", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_queryMessageFlags() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.queryMessageFlags(payload: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<QueryMessageFlagsResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/moderation/flags/message"
        
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_unmuteChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.unmuteChannel(unmuteChannelRequest: .init(channelCid: "id", channelCids: ["id"]), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UnmuteResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/moderation/unmute/channel"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(UnmuteChannelRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_uploadFile() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.uploadFile(type: "type", id: "id", fileUploadRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<FileUploadResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/file"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(FileUploadRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_deleteFile() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.deleteFile(type: "type", id: "id", url: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<FileDeleteResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/file"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let urlQueryItem = URLQueryItem(name: "url", value: "")
        queryParams.append(urlQueryItem)
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }

    public func test_apiRequest_getOrCreateChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        let connectionId = String.unique
        connectionDetailsProvider.provideConnectionIdResult = .success(connectionId)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.getOrCreateChannel(type: "type", id: "id", channelGetOrCreateRequest: .init(), requiresConnectionId: true, completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<ChannelStateResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/query"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        let connectionIdValue = URLQueryItem(name: "connection_id", value: connectionId)
        queryParams.append(connectionIdValue)

        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(ChannelGetOrCreateRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_markRead() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.markRead(type: "type", id: "id", markReadRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MarkReadResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/read"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(MarkReadRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_runMessageAction() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.runMessageAction(id: "id", messageActionRequest: .init(formData: [:]), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MessageResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}/action"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(MessageActionRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_deleteReaction() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.deleteReaction(id: "id", type: "type", userId: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<ReactionRemovalResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}/reaction/{type}"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let userIdQueryItem = URLQueryItem(name: "user_id", value: "")
        queryParams.append(userIdQueryItem)
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }

    public func test_apiRequest_ban() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.ban(banRequest: .init(targetUserId: "id"), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<Response, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/moderation/ban"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(BanRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_unban() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.unban(targetUserId: .init(), type: .init(), id: .init(), createdBy: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<Response, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/moderation/ban"
        
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }

    public func test_apiRequest_queryUsers() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.queryUsers(payload: .init(.init(filterConditions: [:])), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UsersResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/users"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let filter = URLQueryItem(name: "payload", value: "{\"filter_conditions\":{}}")
        queryParams.append(filter)
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_updateUsers() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.updateUsers(updateUsersRequest: .init(users: [:]), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UpdateUsersResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/users"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(UpdateUsersRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_updateUsersPartial() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.updateUsersPartial(updateUserPartialRequest: .init(id: "id", unset: [], set: [:]), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UpdateUsersResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/users"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "PATCH")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(UpdateUserPartialRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_unmuteUser() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.unmuteUser(unmuteUserRequest: .init(targetId: "id", targetIds: ["id"]), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UnmuteResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/moderation/unmute"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(UnmuteUserRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_queryBannedUsers() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.queryBannedUsers(payload: .init(.init(filterConditions: [:])), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<QueryBannedUsersResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/query_banned_users"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let filter = URLQueryItem(name: "payload", value: "{\"filter_conditions\":{}}")
        queryParams.append(filter)
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_queryChannels() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        let connectionId = String.unique
        connectionDetailsProvider.provideConnectionIdResult = .success(connectionId)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.queryChannels(queryChannelsRequest: .init(), requiresConnectionId: true, completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<ChannelsResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        let path = "/api/v2/chat/channels"
        
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        let connectionIdValue = URLQueryItem(name: "connection_id", value: connectionId)
        queryParams.append(connectionIdValue)
                        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(QueryChannelsRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_showChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.showChannel(type: "type", id: "id", showChannelRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<ShowChannelResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/show"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(ShowChannelRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_truncateChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.truncateChannel(type: "type", id: "id", truncateChannelRequest: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<TruncateChannelResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}/truncate"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(TruncateChannelRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_getMessage() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.getMessage(id: "id", completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MessageWithPendingMetadataResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    public func test_apiRequest_updateMessage() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.updateMessage(id: "id", updateMessageRequest: .init(message: .init(attachments: [])), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UpdateMessageResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(UpdateMessageRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_updateMessagePartial() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.updateMessagePartial(id: "id", updateMessagePartialRequest: .init(unset: [], set: [:]), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UpdateMessagePartialResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "PUT")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(UpdateMessagePartialRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_deleteMessage() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.deleteMessage(id: "id", hard: .init(), deletedBy: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<MessageResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }

    public func test_apiRequest_sendReaction() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.sendReaction(id: "id", sendReactionRequest: .init(reaction: .init(type: "like")), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<ReactionResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/messages/{id}/reaction"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(SendReactionRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_updateChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.updateChannel(type: "type", id: "id", updateChannelRequest: .init(addModerators: [], demoteModerators: [], removeMembers: []), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UpdateChannelResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "POST")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(UpdateChannelRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }

    public func test_apiRequest_deleteChannel() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.deleteChannel(type: "type", id: "id", hardDelete: .init(), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<DeleteChannelResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)
        XCTAssertEqual(request?.httpMethod, "DELETE")
    }

    public func test_apiRequest_updateChannelPartial() throws {
        // Given
        let apiClient = APIClient_Spy()
        let api = API.mock(with: apiClient, encoder: encoder)

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // When
        let expectation = expectation(description: "request")
        api.updateChannelPartial(type: "type", id: "id", updateChannelPartialRequest: .init(unset: [], set: [:]), completion: { _ in
            expectation.fulfill()
        })

        // We are not interested in the result of the request, only in the request itself
        apiClient.test_simulateResponse(
            Result<UpdateChannelPartialResponse, Error>.failure(ClientError.Unknown())
        )

        waitForExpectations(timeout: defaultTimeout)

        // Then
        let request = apiClient.current_request
        var path = "/api/v2/chat/channels/{type}/{id}"
        
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: "type", options: .literal, range: nil)
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: "id", options: .literal, range: nil)
        XCTAssertEqual(request?.url?.relativePath, path)

        var queryParams = [URLQueryItem]()
        let apiKey = URLQueryItem(name: "api_key", value: apiKey.apiKeyString)
        queryParams.append(apiKey)
        
        XCTAssertEqual(request?.queryItems, queryParams)
        XCTAssertEqual(request?.httpMethod, "PATCH")
        if let httpBody = request?.httpBody {
            let body = try? JSONDecoder.default.decode(UpdateChannelPartialRequest.self, from: httpBody)
            XCTAssertNotNil(body)
        }
    }
}
