//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class APIClient_Tests: XCTestCase {
    var apiClient: APIClient!
    
    var apiKey: APIKey!
    var baseURL: URL!
    var sessionConfiguration: URLSessionConfiguration!
    
    var uniqueHeaderValue: String!
    
    var encoder: TestRequestEncoder!
    var decoder: TestRequestDecoder!
    var cdnClient: CDNClient_Mock!
    var tokenRefresher: ((@escaping () -> Void) -> Void)!
    var queueOfflineRequest: QueueOfflineRequestBlock!

    override func setUp() {
        super.setUp()
        
        apiKey = APIKey(.unique)
        baseURL = .unique()
        
        // Prepare the URL protocol test environment
        sessionConfiguration = .ephemeral
        RequestRecorderURLProtocol.startTestSession(with: &sessionConfiguration)
        MockNetworkURLProtocol.startTestSession(with: &sessionConfiguration)
        sessionConfiguration.httpMaximumConnectionsPerHost = Int.max
        
        // Some random value to ensure the headers are respected
        uniqueHeaderValue = .unique
        sessionConfiguration.httpAdditionalHeaders?["unique_value"] = uniqueHeaderValue
        
        encoder = TestRequestEncoder(baseURL: baseURL, apiKey: apiKey)
        decoder = TestRequestDecoder()
        cdnClient = CDNClient_Mock()
        tokenRefresher = { _ in }
        queueOfflineRequest = { _ in }
        
        apiClient = APIClient(
            sessionConfiguration: sessionConfiguration,
            requestEncoder: encoder,
            requestDecoder: decoder,
            CDNClient: cdnClient,
            tokenRefresher: tokenRefresher,
            queueOfflineRequest: queueOfflineRequest
        )
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&apiClient)
        
        RequestRecorderURLProtocol.reset()
        MockNetworkURLProtocol.reset()
        
        super.tearDown()
    }
    
    func test_isInitializedWithCorrectValues() {
        XCTAssert(apiClient.encoder as AnyObject === encoder)
        XCTAssert(apiClient.decoder as AnyObject === decoder)
        XCTAssertTrue(apiClient.session.configuration.isTestEqual(to: sessionConfiguration))
    }

    // MARK: - Request
    
    func test_requestEncoderIsCalledWithEndpoint() {
        // Setup mock encoder response (it's not actually used, we just need to return something)
        let request = URLRequest(url: .unique())
        encoder.encodeRequest = .success(request)
        
        // Create a test endpoint
        let testEndpoint = Endpoint<Data>(path: .guest, method: .post, queryItems: nil, requiresConnectionId: false, body: nil)
        
        // Create a request
        waitUntil { done in
            apiClient.request(endpoint: testEndpoint) { _ in
                done()
            }
        }

        // Check the encoder is called with the correct endpoint
        XCTAssertEqual(encoder.encodeRequest_endpoints.first, AnyEndpoint(testEndpoint))
        XCTEnsureRequestsWereExecuted(times: 1)
    }
    
    func test_requestEncoderFailingToEncode() throws {
        // Setup mock encoder response to fail with `testError`
        let testError = TestError()
        encoder.encodeRequest = .failure(testError)
        
        // Create a test endpoint
        let testEndpoint = Endpoint<Data>.mock()
        
        // Create a request and assert the result is failure
        let result = try waitFor { apiClient.request(endpoint: testEndpoint, completion: $0) }
        AssertResultFailure(result, testError)
        XCTAssertCall("encodeRequest(for:completion:)", on: encoder, times: 1)
        XCTAssertNotCall("decodeRequestResponse(data:response:error:)", on: decoder)
    }

    func test_callingRequest_createsNetworkRequest() throws {
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
        waitUntil { done in
            apiClient.request(endpoint: testEndpoint) { _ in done() }
        }
        
        // Check a network request is made with the values from `testRequest`
        AssertNetworkRequest(
            method: .post,
            path: "/" + uniquePath,
            // the "name" header value comes from the request, "unique_value" from the session config
            headers: ["surname": "Organa", "unique_value": uniqueHeaderValue],
            queryParameters: ["item": uniqueQueryItem],
            body: try JSONEncoder().encode(["name": "Leia"])
        )
        XCTAssertCall("encodeRequest(for:completion:)", on: encoder, times: 1)
        XCTEnsureRequestsWereExecuted(times: 1)
    }
    
    func test_requestSuccess() throws {
        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        encoder.encodeRequest = .success(testRequest)
        
        // Set up a successful mock network response for the request
        let mockNetworkResponseData = try JSONEncoder.stream.encode(TestUser(name: "Network Response"))
        MockNetworkURLProtocol.mockResponse(request: testRequest, statusCode: 234, responseBody: mockNetworkResponseData)
        
        // Set up a decoder response
        // ⚠️ Watch out: the user is different there, so we can distinguish between the incoming data
        // to the encoder, and the outgoing data).
        let mockDecoderResponseData = TestUser(name: "Decoder Response")
        decoder.decodeRequestResponse = .success(mockDecoderResponseData)
        
        // Create a test endpoint (it's actually ignored, because APIClient uses the testRequest returned from the encoder)
        let testEndpoint = Endpoint<TestUser>.mock()
        
        // Create a request and wait for the completion block
        let result = try waitFor { apiClient.request(endpoint: testEndpoint, completion: $0) }
        
        // Check the incoming data to the encoder is the URLResponse and data from the network
        XCTAssertEqual(decoder.decodeRequestResponse_data, mockNetworkResponseData)
        XCTAssertEqual(decoder.decodeRequestResponse_response?.statusCode, 234)
        
        // Check the outgoing data from the encoder is the result data
        AssertResultSuccess(result, mockDecoderResponseData)
        XCTEnsureRequestsWereExecuted(times: 1)
    }
    
    func test_requestFailure() throws {
        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        encoder.encodeRequest = .success(testRequest)
        
        // We cannot use `TestError` since iOS14 wraps this into another error
        let networkError = NSError(domain: "TestNetworkError", code: -1, userInfo: nil)
        let encoderError = TestError()
        
        // Set up a mock network response from the request
        MockNetworkURLProtocol.mockResponse(request: testRequest, statusCode: 444, error: networkError)
        
        // Set up a decoder response to return `encoderError`
        decoder.decodeRequestResponse = .failure(encoderError)
        
        // Create a test endpoint (it's actually ignored, because APIClient uses the testRequest returned from the encoder)
        let testEndpoint = Endpoint<TestUser>.mock()
        
        // Create a request and wait for the completion block
        let result = try waitFor { apiClient.request(endpoint: testEndpoint, completion: $0) }
        
        // Check the incoming error to the encoder is the error from the response
        XCTAssertNotNil(decoder.decodeRequestResponse_error)
        // We have to compare error codes, since iOS14 wraps network errors into `NSURLError`
        // in which we cannot retrieve the wrapper error
        XCTAssertEqual((decoder.decodeRequestResponse_error as NSError?)?.code, networkError.code)
        
        // Check the outgoing error from the encoder is the result data
        AssertResultFailure(result, encoderError)
        XCTEnsureRequestsWereExecuted(times: 1)
    }

    func test_requestConnectionFailure() throws {
        // Set up a decoder response to return `NSURLErrorNotConnectedToInternet` error.
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        decoder.decodeRequestResponse = .failure(networkError)

        var offlineRequestQueued = false
        createClient(queueOfflineRequest: { _ in
            offlineRequestQueued = true
        })

        // Create a test endpoint (it's actually ignored, because APIClient uses the testRequest returned from the encoder)
        let testEndpoint = Endpoint<TestUser>.mock()

        // Create a request and wait for the completion block
        let result = try waitFor { apiClient.request(endpoint: testEndpoint, completion: $0) }

        // When reaching the maximum retries, it gets the request queued
        AssertResultFailure(result, networkError)
        XCTEnsureRequestsWereExecuted(times: 4)
        XCTAssertTrue(offlineRequestQueued)
    }

    func test_startingMultipleRequestsAtTheSameTimeShouldResultInParallelRequests() {
        createClient(tokenRefresher: { _ in
            // If token refresh never completes, it will never complete the request
        })

        let encoderError = ClientError.ExpiredToken()
        decoder.decodeRequestResponse = .failure(encoderError)

        // We run two operations at the same time. None of them will complete
        apiClient.request(endpoint: Endpoint<TestUser>.mock(), completion: { _ in
            XCTFail()
        })
        apiClient.request(endpoint: Endpoint<TestUser>.mock(), completion: { _ in
            XCTFail()
        })

        AssertAsync.willBeEqual(decoder.numberOfCalls(on: "decodeRequestResponse(data:response:error:)"), 2)
        // Both are executed even though none of them have completed
        XCTEnsureRequestsWereExecuted(times: 2)
    }

    // MARK: - Request retries

    func test_runningARequestWithConnectivityIssues() {
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        decoder.decodeRequestResponse = .failure(networkError)

        let expectation = self.expectation(description: "Request completes")
        apiClient.request(endpoint: Endpoint<TestUser>.mock(), completion: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.1, handler: nil)

        // Retries until the maximum amount
        XCTEnsureRequestsWereExecuted(times: 4)
    }

    func test_runningARequestAndSwitchingToRecoveryMode() {
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        decoder.decodeRequestResponse = .failure(networkError)

        let expectation = self.expectation(description: "Request completes")
        apiClient.request(endpoint: Endpoint<TestUser>.mock(), completion: { _ in
            expectation.fulfill()
        })
        apiClient.enterRecoveryMode()

        // We expect only one request (the initial one) to go through
        AssertAsync.willBeTrue(decoder.numberOfCalls(on: "decodeRequestResponse(data:response:error:)") == 1)

        // Gets enqueued because we switched to recovery mode
        XCTEnsureRequestsWereExecuted(times: 1)

        // We restart the regular queue
        decoder.decodeRequestResponse = .success(TestUser(name: .unique))
        apiClient.exitRecoveryMode()

        waitForExpectations(timeout: 0.1, handler: nil)
        XCTEnsureRequestsWereExecuted(times: 2)
    }

    // MARK: - CDN Client
    
    func test_uploadAttachment_calls_CDNClient() throws {
        let attachment = AnyChatMessageAttachment.sample()
        let mockedProgress: Double = 42
        let mockedURL = URL(string: "https://hello.com")!
        cdnClient.uploadAttachmentProgress = mockedProgress
        cdnClient.uploadAttachmentResult = .success(mockedURL)

        var receivedProgress: Double?
        var receivedResult: Result<URL, Error>?
        waitUntil { done in
            apiClient.uploadAttachment(
                attachment,
                progress: { receivedProgress = $0 },
                completion: { receivedResult = $0; done() }
            )
        }

        XCTAssertCall("uploadAttachment(_:progress:completion:)", on: cdnClient, times: 1)
        XCTAssertEqual(receivedProgress, mockedProgress)
        XCTAssertEqual(receivedResult?.value, mockedURL)
    }

    // MARK: - Token Refresh
    
    func test_requestFailedWithExpiredToken_refreshesToken() throws {
        var tokenRefresherWasCalled = false
        createClient(tokenRefresher: { _ in
            tokenRefresherWasCalled = true
        })

        let encoderError = ClientError.ExpiredToken()
        decoder.decodeRequestResponse = .failure(encoderError)

        let testEndpoint = Endpoint<TestUser>.mock()
        apiClient.request(endpoint: testEndpoint, completion: { _ in })
        
        AssertAsync.willBeTrue(tokenRefresherWasCalled)
        XCTEnsureRequestsWereExecuted(times: 1)
    }

    func test_requestFailedWithExpiredToken_requeuedOperationAndRetries() throws {
        var completeTokenRefresh = {}
        let tokenRefreshIsCalled = expectation(description: "Token refresh is called")
        createClient(tokenRefresher: { completion in
            tokenRefreshIsCalled.fulfill()
            completeTokenRefresh = completion
        })

        let encoderError = ClientError.ExpiredToken()
        decoder.decodeRequestResponse = .failure(encoderError)

        var result: Result<TestUser, Error>?
        apiClient.request(
            endpoint: Endpoint<TestUser>.mock(),
            completion: {
                result = $0
            }
        )
        wait(for: [tokenRefreshIsCalled], timeout: 0.5)

        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)
        completeTokenRefresh()

        AssertAsync.willBeTrue(result != nil)

        if case let .success(user) = result {
            XCTAssertEqual(user, testUser)
        } else {
            XCTFail()
        }
        XCTEnsureRequestsWereExecuted(times: 2)
    }
    
    func test_requestFailedWithExpiredToken_retriesRequestUntilReachingMaximumAttempts() throws {
        var tokenRefresherWasCalled = false
        createClient(tokenRefresher: { completion in
            tokenRefresherWasCalled = true
            completion()
        })
        
        let encoderError = ClientError.ExpiredToken()
        decoder.decodeRequestResponse = .failure(encoderError)

        var result: Result<TestUser, Error>?
        waitUntil(timeout: 0.2) { done in
            apiClient.request(
                endpoint: Endpoint<TestUser>.mock(),
                completion: {
                    result = $0; done()
                }
            )
        }

        XCTAssertTrue(tokenRefresherWasCalled)

        guard let result = result, case let .failure(error) = result else {
            XCTFail()
            return
        }

        XCTAssertTrue(error is ClientError.TooManyTokenRefreshAttempts)
        // 1 request + 10 refresh attempts
        XCTEnsureRequestsWereExecuted(times: 11)
    }

    // MARK: - Flush

    func test_flushRequestsQueue_whenThereAreOperationsOngoing_shouldStopQueuedOnes() {
        var completeTokenRefresh = {}
        let tokenRefreshIsCalled = expectation(description: "Token refresh is called")
        createClient(tokenRefresher: { completion in
            tokenRefreshIsCalled.fulfill()
            completeTokenRefresh = completion
        })

        let encoderError = ClientError.ExpiredToken()
        decoder.decodeRequestResponse = .failure(encoderError)
        apiClient.request(
            endpoint: Endpoint<TestUser>.mock(),
            completion: { _ in
                XCTFail("Should not complete")
            }
        )

        wait(for: [tokenRefreshIsCalled], timeout: 0.1)
        // The queue is now paused waiting for a token refresh response

        // 1. We add 5 more requests to the queue
        (1...5).forEach { _ in
            self.apiClient.request(endpoint: Endpoint<TestUser>.mock(), completion: { _ in })
        }

        // 2. We make sure they succeed if they are ever executed
        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)

        // 3. We flush the queue
        apiClient.flushRequestsQueue()

        // 4. We restart the queue by completing the token refresh
        completeTokenRefresh()

        // 5. We apply a delay to verify that only one request (the initial one) went through
        waitUntil { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                done()
            }
        }
        XCTEnsureRequestsWereExecuted(times: 1)
    }

    // MARK: - Recovery mode

    func test_whenInRecoveryModeRegularRequestsShouldNotGoThrough() {
        apiClient.enterRecoveryMode()

        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)
        (1...5).forEach { _ in
            self.apiClient.request(endpoint: Endpoint<TestUser>.mock(), completion: { _ in })
        }

        // 5. We apply a delay to verify that no requests are going through
        waitUntil { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                done()
            }
        }
        XCTAssertNotCall("encodeRequest(for:completion:)", on: encoder)
        XCTAssertNotCall("decodeRequestResponse(data:response:error:)", on: decoder)
    }

    func test_whenInRecoveryModeRecoveryRequestsShouldGoThrough() {
        apiClient.enterRecoveryMode()

        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)
        let lastRequestExpectation = expectation(description: "Last request completed")
        (1...5).forEach { index in
            let channelId = ChannelId(type: .messaging, id: "\(index)")
            self.apiClient.recoveryRequest(endpoint: Endpoint<TestUser>.mock(path: .sendMessage(channelId))) { _ in
                if index == 5 {
                    lastRequestExpectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 0.5, handler: nil)
        XCTEnsureRequestsWereExecuted(times: 5)
    }

    func test_whenInRegularModeRecoveryRequestsShouldThrowAnAssert() {
        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)
        let loggerMock = LoggerMock()
        loggerMock.injectMock()

        let lastRequestExpectation = expectation(description: "Last request completed")
        (1...5).forEach { index in
            self.apiClient.recoveryRequest(endpoint: Endpoint<TestUser>.mock(), completion: { _ in
                if index == 5 { lastRequestExpectation.fulfill() }
            })
        }

        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(loggerMock.assertionFailureCalls, 5)
        XCTAssertCall("encodeRequest(for:completion:)", on: encoder, times: 5)
        XCTAssertCall("decodeRequestResponse(data:response:error:)", on: decoder, times: 5)
    }

    func test_whenInRecoveryMode_startingMultipleRecoveryRequestsAtTheSameTimeShouldRunThemInSerial() {
        apiClient.enterRecoveryMode()

        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)
        decoder.decodeRequestDelay = 0.01

        let lastRequestExpectation = expectation(description: "Last request completed")
        let testBlock: (Int) -> Void = { index in
            // Given a request, the total amount of requests executed should equal the index
            self.XCTEnsureRequestsWereExecuted(times: index)
            if index == 5 {
                lastRequestExpectation.fulfill()
            }
        }
        (1...5).forEach { index in
            let channelId = ChannelId(type: .messaging, id: "\(index)")
            self.apiClient.recoveryRequest(endpoint: Endpoint<TestUser>.mock(path: .sendMessage(channelId))) { _ in
                testBlock(index)
            }
        }

        waitForExpectations(timeout: 0.5, handler: nil)
        XCTEnsureRequestsWereExecuted(times: 5)
    }

    func test_whenInRecoveryModeAndARequestFailsOrderShouldBeKeptWhenRetrying() {
        var complete3rdTokenRefresh = {}
        var tokenRefreshCalls = 0
        let tokenRefreshIsCalled3Times = expectation(description: "Token refresh is called")
        createClient(tokenRefresher: { completion in
            tokenRefreshCalls += 1
            if tokenRefreshCalls == 3 {
                tokenRefreshIsCalled3Times.fulfill()
                complete3rdTokenRefresh = completion
            } else {
                completion()
            }
        })

        apiClient.enterRecoveryMode()
        let encoderError = ClientError.ExpiredToken()
        decoder.decodeRequestResponse = .failure(encoderError)

        // Put 5 requests on the queue. Only one should be executed at a time
        let lastRequestExpectation = expectation(description: "Last request completed")
        var results: [Result<TestUser, Error>] = []
        (1...5).forEach { index in
            let channelId = ChannelId(type: .messaging, id: "\(index)")
            self.apiClient.recoveryRequest(endpoint: Endpoint<TestUser>.mock(path: .sendMessage(channelId))) { result in
                results.append(result)
                if index == 5 {
                    lastRequestExpectation.fulfill()
                }
            }
        }

        wait(for: [tokenRefreshIsCalled3Times], timeout: 0.1)

        // 3 tries, token failure was returned until now
        // -> 1 unique | 3 total
        XCTEnsureRequestsWereExecuted(times: 3)
        let requestPaths = encoder.encodeRequest_endpoints.map(\.path.value)
        XCTAssertEqual(requestPaths.count, 3)
        XCTAssertEqual(Set(requestPaths).count, 1)

        // From now on we will let it through
        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)

        complete3rdTokenRefresh()

        waitForExpectations(timeout: 0.1, handler: nil)

        // Request 1: 3 token failures + 1 success = 4
        // Requests 2-5: 1 success each = 4
        // -> 5 unique | 8 total
        XCTEnsureRequestsWereExecuted(times: 8)
        let totalRequests = encoder.encodeRequest_endpoints.map(\.path.value)
        XCTAssertEqual(totalRequests.count, 8)
        XCTAssertEqual(Set(totalRequests).count, 5)
    }

    // MARK: - Helpers

    private func XCTEnsureRequestsWereExecuted(times: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertCall("encodeRequest(for:completion:)", on: encoder, times: times, file: file, line: line)
        XCTAssertCall("decodeRequestResponse(data:response:error:)", on: decoder, times: times, file: file, line: line)
    }

    private func createClient(
        tokenRefresher: ((@escaping () -> Void) -> Void)? = nil,
        queueOfflineRequest: QueueOfflineRequestBlock? = nil
    ) {
        if let tokenRefresher = tokenRefresher {
            self.tokenRefresher = tokenRefresher
        }
        if let queueOfflineRequest = queueOfflineRequest {
            self.queueOfflineRequest = queueOfflineRequest
        }
        apiClient = APIClient(
            sessionConfiguration: sessionConfiguration,
            requestEncoder: encoder,
            requestDecoder: decoder,
            CDNClient: cdnClient,
            tokenRefresher: self.tokenRefresher,
            queueOfflineRequest: self.queueOfflineRequest
        )
    }
}

extension Endpoint {
    static func mock(path: EndpointPath = .guest) -> Endpoint<ResponseType> {
        .init(path: path, method: .post, queryItems: nil, requiresConnectionId: false, body: nil)
    }
}

private struct TestUser: Codable, Equatable {
    let name: String
}

class TestRequestEncoder: RequestEncoder, Spy {
    var recordedFunctions: [String] = []
    let init_baseURL: URL
    let init_apiKey: APIKey
    
    weak var connectionDetailsProviderDelegate: ConnectionDetailsProviderDelegate?
    
    var encodeRequest: Result<URLRequest, Error>? = .success(URLRequest(url: .unique()))
    var encodeRequest_endpoints: [AnyEndpoint] = []
    var encodeRequest_completion: ((Result<URLRequest, Error>) -> Void)?
    
    func encodeRequest<ResponsePayload>(
        for endpoint: Endpoint<ResponsePayload>,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) where ResponsePayload: Decodable {
        record()
        encodeRequest_endpoints.append(AnyEndpoint(endpoint))
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

class TestRequestDecoder: RequestDecoder, Spy {
    var recordedFunctions: [String] = []
    var decodeRequestResponse: Result<Any, Error>?
    var decodeRequestDelay: TimeInterval?

    var decodeRequestResponse_data: Data?
    var decodeRequestResponse_response: HTTPURLResponse?
    var decodeRequestResponse_error: Error?
    
    func decodeRequestResponse<ResponseType>(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) throws -> ResponseType where ResponseType: Decodable {
        record()
        decodeRequestResponse_data = data
        decodeRequestResponse_response = response as? HTTPURLResponse
        decodeRequestResponse_error = error

        guard let simulatedResponse = decodeRequestResponse else {
            log.warning("TestRequestDecoder simulated response not set. Throwing a TestError.")
            throw TestError()
        }

        if let decodeRequestDelay = decodeRequestDelay {
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.asyncAfter(deadline: .now() + decodeRequestDelay) { group.leave() }
            group.wait()
        }
        switch simulatedResponse {
        case let .success(response):
            return response as! ResponseType
        case let .failure(error):
            throw error
        }
    }
}

extension AnyEncodable: Equatable {
    public static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
        do {
            let encoder = JSONEncoder.default
            let encodedLhs = try encoder.encode(lhs)
            let encodedRhs = try encoder.encode(rhs)
            try CompareJSONEqual(encodedLhs, encodedRhs)
            return true
        } catch {
            return String(describing: lhs) == String(describing: rhs)
        }
    }
}

struct AnyEndpoint: Equatable {
    let path: EndpointPath
    let method: EndpointMethod
    let queryItems: AnyEncodable?
    let requiresConnectionId: Bool
    let body: AnyEncodable?
    let payloadType: Decodable.Type
    
    init<T: Decodable>(_ endpoint: Endpoint<T>) {
        path = endpoint.path
        method = endpoint.method
        queryItems = endpoint.queryItems?.asAnyEncodable
        requiresConnectionId = endpoint.requiresConnectionId
        body = endpoint.body?.asAnyEncodable
        payloadType = T.self
    }
    
    static func == (lhs: AnyEndpoint, rhs: AnyEndpoint) -> Bool {
        lhs.path.value == rhs.path.value
            && lhs.method == rhs.method
            && lhs.queryItems == rhs.queryItems
            && lhs.requiresConnectionId == rhs.requiresConnectionId
            && lhs.body == rhs.body
            && lhs.payloadType == rhs.payloadType
    }
}

extension URLSessionConfiguration {
    // Because on < iOS13 the configuration class gets copied and we can't simply compare it's the same instance, we need to
    // provide custom implementation for comparing. The default `Equatable` implementation of `URLSessionConfiguration`
    // simply compares the pointers.
    @available(iOS, deprecated: 12.0, message: "Remove this workaround when dropping iOS 12 support.")
    func isTestEqual(to otherConfiguration: URLSessionConfiguration) -> Bool {
        let commonEquatability = identifier == otherConfiguration.identifier
            && requestCachePolicy == otherConfiguration.requestCachePolicy
            && timeoutIntervalForRequest == otherConfiguration.timeoutIntervalForRequest
            && timeoutIntervalForResource == otherConfiguration.timeoutIntervalForResource
            && networkServiceType == otherConfiguration.networkServiceType
            && allowsCellularAccess == otherConfiguration.allowsCellularAccess
            && httpShouldUsePipelining == otherConfiguration.httpShouldUsePipelining
            && httpShouldSetCookies == otherConfiguration.httpShouldSetCookies
            && httpCookieAcceptPolicy == otherConfiguration.httpCookieAcceptPolicy
            && httpAdditionalHeaders as? [String: String] == otherConfiguration.httpAdditionalHeaders as? [String: String]
            && httpMaximumConnectionsPerHost == otherConfiguration.httpMaximumConnectionsPerHost
            && httpCookieStorage == otherConfiguration.httpCookieStorage
            && urlCredentialStorage == otherConfiguration.urlCredentialStorage
            && urlCache == otherConfiguration.urlCache
            && shouldUseExtendedBackgroundIdleMode == otherConfiguration.shouldUseExtendedBackgroundIdleMode
            && waitsForConnectivity == otherConfiguration.waitsForConnectivity
            && isDiscretionary == otherConfiguration.isDiscretionary
            && sharedContainerIdentifier == otherConfiguration.sharedContainerIdentifier
            && waitsForConnectivity == otherConfiguration.waitsForConnectivity
            && isDiscretionary == otherConfiguration.isDiscretionary
            && sharedContainerIdentifier == otherConfiguration.sharedContainerIdentifier
        
        #if os(iOS)
        return commonEquatability
            && multipathServiceType == otherConfiguration.multipathServiceType
            && sessionSendsLaunchEvents == otherConfiguration.sessionSendsLaunchEvents
        #else
        return commonEquatability
        #endif
    }
}
