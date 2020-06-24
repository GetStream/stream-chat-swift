//
// APIClient_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class APIClient_Tests: XCTestCase {
    var apiClient: APIClient!
    
    var apiKey: APIKey!
    var baseURL: URL!
    var sessionConfiguration: URLSessionConfiguration!
    
    var uniqeHeaderValue: String!
    
    var encoder: TestRequestEncoder { apiClient.encoder as! TestRequestEncoder }
    var decoder: TestRequestDecoder { apiClient.decoder as! TestRequestDecoder }
    
    override func setUp() {
        super.setUp()
        
        let environment = APIClient.Environment(requestEncoderBuilder: TestRequestEncoder.init,
                                                requestDecoderBuilder: TestRequestDecoder.init)
        
        apiKey = APIKey(.unique)
        baseURL = .unique()
        
        // Prepare the URL protocol test environment
        sessionConfiguration = URLSessionConfiguration.default
        RequestRecorderURLProtocol.startTestSession(with: &sessionConfiguration)
        MockNetworkURLProtocol.startTestSession(with: &sessionConfiguration)
        
        // Some random value to ensure the headers are respected
        uniqeHeaderValue = .unique
        sessionConfiguration.httpAdditionalHeaders?["unique_value"] = uniqeHeaderValue
        
        apiClient = APIClient(apiKey: apiKey, baseURL: baseURL, sessionConfiguration: sessionConfiguration,
                              environment: environment)
    }
    
    override func tearDown() {
        // Test APIClient has no retain cycles after every test
        weak var weakAPIClient = apiClient
        apiClient = nil
        XCTAssertNil(weakAPIClient)
        
        super.tearDown()
    }
    
    func test_isInitializedWithCorrectValues() {
        XCTAssertEqual(apiClient.baseURL, baseURL)
        XCTAssertEqual(apiClient.apiKey, apiKey)
        XCTAssertEqual(apiClient.session.configuration, sessionConfiguration)
    }
    
    // MARK: - Connection Id handling
    
    func test_providesConnectionIdForEncoder() {
        // Simulate WS client updated connection id
        let connectionId1: ConnectionId = .unique
        apiClient.webSocketClient(TestWebSocketClient(), didUpdateConectionState: .connected(connectionId: connectionId1))
        
        // Simulate encoder requested a connection id and check it's the correct one
        var providedConnectionId1: ConnectionId?
        encoder.connectionIdProviderDelegate?.provideConnectionId { providedConnectionId1 = $0 }
        XCTAssertEqual(providedConnectionId1, connectionId1)
        
        // Simulate WS client is disconnecting
        apiClient.webSocketClient(TestWebSocketClient(), didUpdateConectionState: .disconnecting(source: .userInitiated))
        
        // Request a connection id again
        var providedConnectionId2: ConnectionId?
        encoder.connectionIdProviderDelegate?.provideConnectionId { providedConnectionId2 = $0 }
        
        // No connection id should be returned
        XCTAssertNil(providedConnectionId2)
        
        // Simulate WS reconnected and check the provided id is correct
        let connectionId2: ConnectionId = .unique
        apiClient.webSocketClient(TestWebSocketClient(), didUpdateConectionState: .connected(connectionId: connectionId2))
        XCTAssertEqual(providedConnectionId2, connectionId2)
    }
    
    func test_waitingRequestsAreFailed_whenAPIClientIsDeallocated() {
        // Simulate encoder requested connection id
        var providedConnectionId1: ConnectionId? = "some_value_that's_not_nil"
        encoder.connectionIdProviderDelegate?.provideConnectionId { providedConnectionId1 = $0 }
        
        // Simulate `APIClient` is deallocated
        apiClient = nil
        
        // Check the callback is called with `nil`
        XCTAssertNil(providedConnectionId1)
    }
    
    // MARK: - Request encoding / decoding
    
    func test_requestEncoderIsCalledWithEndpoint() {
        // Setup mock encoder response (it's not actually used, we just need to return something)
        let request = URLRequest(url: .unique())
        encoder.encodeRequest = .success(request)
        
        // Create a test endpoint
        let testEndpoint = Endpoint<Data>(path: .unique, method: .post, queryItems: nil, requiresConnectionId: false, body: nil)
        
        // Create a request
        apiClient.request(endpoint: testEndpoint) { _ in }
        
        // Check the encoder is called with the correct endpoint
        XCTAssertEqual(encoder.encodeRequest_endpoint, AnyEndpoint(testEndpoint))
    }
    
    func test_requestEncoderFailingToEncode() throws {
        // Setup mock encoder response to fail with `testError`
        let testError = TestError()
        encoder.encodeRequest = .failure(testError)
        
        // Create a test endpoint
        let testEndpoint = Endpoint<Data>.mock()
        
        // Create a request and assert the result is failure
        let result = try await { apiClient.request(endpoint: testEndpoint, completion: $0) }
        AssertResultFailure(result, testError)
    }
    
    // MARK: - Networking
    
    func test_callingRequest_createsNetworkRequest() {
        // Create a test request and set it as a response from the encoder
        let uniquePath: String = .unique
        let uniqueQueryItem: String = .unique
        var testRequest = URLRequest(url: URL(string: "test://test.test/\(uniquePath)?item=\(uniqueQueryItem)")!)
        testRequest.httpMethod = "post"
        testRequest.httpBody = try! JSONEncoder.stream.encode(TestUser(name: "Leia"))
        testRequest.allHTTPHeaderFields?["surname"] = "Organa"
        encoder.encodeRequest = .success(testRequest)
        
        // Create a test endpoint (it's actually ignored, because APIClient uses the testRequest returned from the encoder)
        let testEndpoint = Endpoint<Data>.mock()
        
        // Create a request
        apiClient.request(endpoint: testEndpoint) { _ in }
        
        // Check a network request is made with the values from `testRequest`
        AssertNetworkRequest(method: .post,
                             path: "/" + uniquePath,
                             // the "name" header value comes from the request, "unique_value" from the session config
                             headers: ["surname": "Organa", "unique_value": uniqeHeaderValue],
                             queryParameters: ["item": uniqueQueryItem],
                             body: ["name": "Leia"])
    }
    
    func test_requestSuccess() throws {
        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        encoder.encodeRequest = .success(testRequest)
        
        // Set up a succssfull mock network response for the request
        let mockResponseData = try JSONEncoder.stream.encode(TestUser(name: "Leia!"))
        MockNetworkURLProtocol.mockResponse(request: testRequest, statusCode: 234, responseBody: mockResponseData)
        
        // Set up a decoder response
        // ⚠️ Watch out: the user is different there, so we can distinguish between the incoming data
        // to the encoder, and the outgoing data).
        decoder.decodeRequestResponse = .success(TestUser(name: "Luke"))
        
        // Create a test endpoint (it's actually ignored, because APIClient uses the testRequest returned from the encoder)
        let testEndpoint = Endpoint<TestUser>.mock()
        
        // Create a request and wait for the completion block
        let result = try await { apiClient.request(endpoint: testEndpoint, completion: $0) }
        
        // Check the incoming data to the encoder is the URLResponse and data from the network
        XCTAssertEqual(decoder.decodeRequestResponse_data, try! JSONEncoder.stream.encode(TestUser(name: "Leia!")))
        XCTAssertEqual(decoder.decodeRequestResponse_response?.statusCode, 234)
        
        // Check the outgoing data from the encoder is the result data
        AssertResultSuccess(result, TestUser(name: "Luke"))
    }
    
    func test_requestFailure() throws {
        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        encoder.encodeRequest = .success(testRequest)
        
        let networkError = TestError()
        let encoderError = TestError()
        
        // Set up a mock network response from the request
        MockNetworkURLProtocol.mockResponse(request: testRequest, statusCode: 444, error: networkError)
        
        // Set up a decoder response to return `encoderError`
        decoder.decodeRequestResponse = .failure(encoderError)
        
        // Create a test endpoint (it's actually ignored, because APIClient uses the testRequest returned from the encoder)
        let testEndpoint = Endpoint<TestUser>.mock()
        
        // Create a request and wait for the completion block
        let result = try await { apiClient.request(endpoint: testEndpoint, completion: $0) }
        
        // Check the incoming error to the encoder is the error from the response
        XCTAssertEqual(decoder.decodeRequestResponse_error as? TestError, networkError)
        
        // Check the outgoing error from the encoder is the result data
        AssertResultFailure(result, encoderError)
    }
}

extension Endpoint {
    static func mock() -> Endpoint<ResponseType> {
        .init(path: .unique, method: .post, queryItems: nil, requiresConnectionId: false, body: nil)
    }
}

private struct TestUser: Codable, Equatable {
    let name: String
}

class TestRequestEncoder: RequestEncoder {
    let init_baseURL: URL
    let init_apiKey: APIKey
    
    weak var connectionIdProviderDelegate: ConnectionIdProviderDelegate?
    
    var encodeRequest: Result<URLRequest, Error>?
    var encodeRequest_endpoint: AnyEndpoint?
    var encodeRequest_completion: ((Result<URLRequest, Error>) -> Void)?
    
    func encodeRequest<ResponsePayload>(
        for endpoint: Endpoint<ResponsePayload>,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) where ResponsePayload: Decodable {
        encodeRequest_endpoint = AnyEndpoint(endpoint)
        encodeRequest_completion = completion
        
        if let result = encodeRequest {
            completion(result)
        }
    }
    
    required init(baseURL: URL, apiKey: APIKey) {
        init_baseURL = baseURL
        init_apiKey = apiKey
    }
}

class TestRequestDecoder: RequestDecoder {
    var decodeRequestResponse: Result<Any, Error>?
    
    var decodeRequestResponse_data: Data?
    var decodeRequestResponse_response: HTTPURLResponse?
    var decodeRequestResponse_error: Error?
    
    func decodeRequestResponse<ResponseType>(data: Data?, response: URLResponse?, error: Error?) throws -> ResponseType
        where ResponseType: Decodable {
        decodeRequestResponse_data = data
        decodeRequestResponse_response = response as? HTTPURLResponse
        decodeRequestResponse_error = error
        
        guard let simulatedResponse = decodeRequestResponse else {
            print("TestRequestDecoder simulated response not set. Throwing a TestError.")
            throw TestError()
        }
        
        switch simulatedResponse {
        case let .success(response):
            return response as! ResponseType
        case let .failure(error):
            throw error
        }
    }
}

struct AnyEndpoint: Equatable {
    let path: String
    let method: EndpointMethod
    let queryItems: Encodable?
    let requiresConnectionId: Bool
    let body: Encodable?
    let payloadType: Decodable.Type
    
    init<T: Decodable>(_ endpoint: Endpoint<T>) {
        path = endpoint.path
        method = endpoint.method
        queryItems = endpoint.queryItems
        requiresConnectionId = endpoint.requiresConnectionId
        body = endpoint.body
        payloadType = T.self
    }
    
    static func == (lhs: AnyEndpoint, rhs: AnyEndpoint) -> Bool {
        lhs.path == rhs.path
            && lhs.method == rhs.method
            && String(describing: lhs.queryItems) == String(describing: rhs.queryItems)
            && lhs.requiresConnectionId == rhs.requiresConnectionId
            && String(describing: lhs.body) == String(describing: rhs.body)
            && String(describing: lhs.payloadType) == String(describing: rhs.payloadType)
    }
}

private class TestWebSocketClient: WebSocketClient {
    init() {
        super.init(urlRequest: .init(url: .unique()), eventDecoder: EventDecoder<DefaultDataTypes>(), eventMiddlewares: [])
    }
}
