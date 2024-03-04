//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class APIClient_Tests: XCTestCase {
    var apiClient: APIClient!

    var apiKey: APIKey!
    var baseURL: URL!
    var sessionConfiguration: URLSessionConfiguration!

    var uniqueHeaderValue: String!

    var encoder: RequestEncoder_Spy!
    var decoder: RequestDecoder_Spy!
    var attachmentUploader: AttachmentUploader_Spy!
    var tokenRefresher: ((@escaping () -> Void) -> Void)!
    var queueOfflineRequest: QueueOfflineRequestBlock!

    override func setUp() {
        super.setUp()

        apiKey = APIKey(.unique)
        baseURL = .unique()

        // Prepare the URL protocol test environment
        sessionConfiguration = .ephemeral
        RequestRecorderURLProtocol_Mock.startTestSession(with: &sessionConfiguration)
        URLProtocol_Mock.startTestSession(with: &sessionConfiguration)
        sessionConfiguration.httpMaximumConnectionsPerHost = Int.max

        // Some random value to ensure the headers are respected
        uniqueHeaderValue = .unique
        sessionConfiguration.httpAdditionalHeaders?["unique_value"] = uniqueHeaderValue

        decoder = RequestDecoder_Spy()
        attachmentUploader = AttachmentUploader_Spy()
        tokenRefresher = { _ in }
        queueOfflineRequest = { _, _ in }

        apiClient = APIClient(
            sessionConfiguration: sessionConfiguration,
            requestDecoder: decoder,
            attachmentUploader: attachmentUploader
        )
        apiClient.tokenRefresher = tokenRefresher
        apiClient.queueOfflineRequest = queueOfflineRequest
    }

    override func tearDown() {
        RequestRecorderURLProtocol_Mock.reset()
        URLProtocol_Mock.reset()
        AssertAsync.canBeReleased(&apiClient)

        apiClient = nil
        baseURL = nil
        sessionConfiguration = nil
        uniqueHeaderValue = nil
        encoder = nil
        decoder = nil
        attachmentUploader = nil
        tokenRefresher = nil
        queueOfflineRequest = nil

        super.tearDown()
    }

    func test_isInitializedWithCorrectValues() {
        XCTAssert(apiClient.decoder as AnyObject === decoder)
        XCTAssertTrue(apiClient.session.configuration.isTestEqual(to: sessionConfiguration))
    }

    // MARK: - Request

    func test_requestSuccess() throws {
        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())

        // Set up a successful mock network response for the request
        let mockNetworkResponseData = try JSONEncoder.stream.encode(TestUser(name: "Network Response"))
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 234, responseBody: mockNetworkResponseData)

        // Set up a decoder response
        // ⚠️ Watch out: the user is different there, so we can distinguish between the incoming data
        // to the encoder, and the outgoing data).
        let mockDecoderResponseData = TestUser(name: "Decoder Response")
        decoder.decodeRequestResponse = .success(mockDecoderResponseData)

        // Create a request and wait for the completion block
        let result: Result<TestUser, Error> = try waitFor {
            apiClient.request(
                testRequest,
                isRecoveryOperation: false,
                completion: $0
            )
        }

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

        // We cannot use `TestError` since iOS14 wraps this into another error
        let networkError = NSError(domain: "TestNetworkError", code: -1, userInfo: nil)
        let encoderError = TestError()

        // Set up a mock network response from the request
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 444, error: networkError)

        // Set up a decoder response to return `encoderError`
        decoder.decodeRequestResponse = .failure(encoderError)

        // Create a request and wait for the completion block
        let result: Result<TestUser, Error> = try waitFor {
            apiClient.request(
                testRequest,
                isRecoveryOperation: false,
                completion: $0
            )
        }

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
        createClient(queueOfflineRequest: { _, _ in
            offlineRequestQueued = true
        })

        // Create a test endpoint (it's actually ignored, because APIClient uses the testRequest returned from the encoder)
        let testEndpoint = URLRequest(url: .unique())

        // Create a request and wait for the completion block
        let result: Result<TestUser, Error> = try waitFor {
            apiClient.request(testEndpoint, isRecoveryOperation: false, completion: $0)
        }

        // When reaching the maximum retries, it gets the request queued
        AssertResultFailure(result, networkError)
        XCTEnsureRequestsWereExecuted(times: 4)
        XCTAssertTrue(offlineRequestQueued)
    }

    func test_startingMultipleRequestsAtTheSameTimeShouldResultInParallelRequests() {
        createClient(tokenRefresher: { _ in
            // If token refresh never completes, it will never complete the request
        })

        let decoderExp = expectation(description: "should call decoder twice")
        decoderExp.expectedFulfillmentCount = 2
        decoder.decodeRequestResponse = .failure(ClientError.ExpiredToken())
        decoder.onDecodeRequestResponseCall = {
            decoderExp.fulfill()
        }
        
        // We run two operations at the same time. None of them will complete
        let completion: (Result<TestUser, Error>) -> Void = { _ in
            XCTFail()
        }
        
        apiClient.request(URLRequest(url: .unique()), isRecoveryOperation: false, completion: completion)
        apiClient.request(URLRequest(url: .unique()), isRecoveryOperation: false, completion: completion)

        waitForExpectations(timeout: defaultTimeout)
    }

    // MARK: - Request retries

    func test_runningARequestWithConnectivityIssues() {
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        decoder.decodeRequestResponse = .failure(networkError)

        let expectation = self.expectation(description: "Request completes")
        let completion: (Result<TestUser, Error>) -> Void = { _ in
            expectation.fulfill()
        }
        apiClient.request(URLRequest(url: .unique()), isRecoveryOperation: false, completion: completion)
        waitForExpectations(timeout: defaultTimeout, handler: nil)

        // Retries until the maximum amount
        XCTEnsureRequestsWereExecuted(times: 4)
    }

    func test_runningARequestAndSwitchingToRecoveryMode() {
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        decoder.decodeRequestResponse = .failure(networkError)

        let expectation = self.expectation(description: "Request completes")
        let completion: (Result<TestUser, Error>) -> Void = { _ in
            expectation.fulfill()
        }
        apiClient.request(URLRequest(url: .unique()), isRecoveryOperation: false, completion: completion)
        apiClient.enterRecoveryMode()

        // We expect only one request (the initial one) to go through
        AssertAsync.willBeTrue(decoder.numberOfCalls(on: "decodeRequestResponse(data:response:error:)") == 1)

        // Gets enqueued because we switched to recovery mode
        XCTEnsureRequestsWereExecuted(times: 1)

        // We restart the regular queue
        decoder.decodeRequestResponse = .success(TestUser(name: .unique))
        apiClient.exitRecoveryMode()

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTEnsureRequestsWereExecuted(times: 2)
    }

    // MARK: - CDN Client

    func test_uploadAttachment_calls_CDNClient() throws {
        let attachment = AnyChatMessageAttachment.dummy()
        let mockedProgress: Double = 42
        let mockedURL = URL(string: "https://hello.com")!
        attachmentUploader.uploadAttachmentProgress = mockedProgress
        attachmentUploader.uploadAttachmentResult = .success(
            UploadedAttachment(
                attachment: attachment,
                remoteURL: mockedURL,
                thumbnailURL: nil
            )
        )

        var receivedProgress: Double?
        var receivedResult: Result<UploadedAttachment, Error>?
        waitUntil(timeout: defaultTimeout) { done in
            apiClient.uploadAttachment(
                attachment,
                progress: { receivedProgress = $0 },
                completion: { receivedResult = $0; done() }
            )
        }

        XCTAssertCall("upload(_:progress:completion:)", on: attachmentUploader, times: 1)
        XCTAssertEqual(receivedProgress, mockedProgress)
        XCTAssertEqual(receivedResult?.value?.remoteURL, receivedResult?.value?.remoteURL)
    }

    func test_uploadAttachment_connectionError() throws {
        let attachment = AnyChatMessageAttachment.dummy()
        let mockedProgress: Double = 42
        attachmentUploader.uploadAttachmentProgress = mockedProgress
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        attachmentUploader.uploadAttachmentResult = .failure(networkError)

        var receivedProgress: Double?
        var receivedResult: Result<UploadedAttachment, Error>?
        let expectation = self.expectation(description: "Upload completes")
        apiClient.uploadAttachment(
            attachment,
            progress: { receivedProgress = $0 },
            completion: { receivedResult = $0; expectation.fulfill() }
        )

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        // Should retry up to 3 times
        XCTAssertCall("upload(_:progress:completion:)", on: attachmentUploader, times: 4)
        XCTAssertEqual(receivedProgress, mockedProgress)
        XCTAssertEqual(receivedResult?.error as NSError?, networkError)
    }

    func test_uploadAttachment_randomError() throws {
        let attachment = AnyChatMessageAttachment.dummy()
        let mockedProgress: Double = 42
        attachmentUploader.uploadAttachmentProgress = mockedProgress
        let error = NSError(domain: "", code: 1, userInfo: nil)
        attachmentUploader.uploadAttachmentResult = .failure(error)

        var receivedProgress: Double?
        var receivedResult: Result<UploadedAttachment, Error>?
        let expectation = self.expectation(description: "Upload completes")
        apiClient.uploadAttachment(
            attachment,
            progress: { receivedProgress = $0 },
            completion: { receivedResult = $0; expectation.fulfill() }
        )

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        // Should only try 1
        XCTAssertCall("upload(_:progress:completion:)", on: attachmentUploader, times: 1)
        XCTAssertEqual(receivedProgress, mockedProgress)
        XCTAssertEqual(receivedResult?.error as NSError?, error)
    }

    // MARK: - Token Refresh

    func test_requestFailedWithExpiredToken_refreshesToken() throws {
        var tokenRefresherWasCalled = false
        createClient(tokenRefresher: { _ in
            tokenRefresherWasCalled = true
        })

        let encoderError = ClientError.ExpiredToken()
        decoder.decodeRequestResponse = .failure(encoderError)

        let completion: (Result<TestUser, Error>) -> Void = { _ in }
        apiClient.request(URLRequest(url: .unique()), isRecoveryOperation: false, completion: completion)

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
            URLRequest(url: .unique()),
            isRecoveryOperation: false,
            completion: {
                result = $0
            }
        )
        wait(for: [tokenRefreshIsCalled], timeout: defaultTimeout)

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
        let completion: (Result<TestUser, Error>) -> Void = { _ in XCTFail("Should not complete") }
        apiClient.request(
            URLRequest(url: .unique()),
            isRecoveryOperation: false,
            completion: completion
        )

        wait(for: [tokenRefreshIsCalled], timeout: defaultTimeout)
        // The queue is now paused waiting for a token refresh response

        // 1. We add 5 more requests to the queue
        let completionQueue: (Result<TestUser, Error>) -> Void = { _ in }
        (1...5).forEach { _ in
            self.apiClient.request(
                URLRequest(url: .unique()),
                isRecoveryOperation: false,
                completion: completionQueue
            )
        }

        // 2. We make sure they succeed if they are ever executed
        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)

        // 3. We flush the queue
        apiClient.flushRequestsQueue()

        // 4. We restart the queue by completing the token refresh
        completeTokenRefresh()

        // 5. We apply a delay to verify that only one request (the initial one) went through
        waitUntil(timeout: defaultTimeout) { done in
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
        // 1. We add 5 more requests to the queue
        let completionQueue: (Result<TestUser, Error>) -> Void = { _ in }
        (1...5).forEach { _ in
            self.apiClient.request(
                URLRequest(url: .unique()),
                isRecoveryOperation: false,
                completion: completionQueue
            )
        }

        // 5. We apply a delay to verify that no requests are going through
        waitUntil(timeout: defaultTimeout) { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                done()
            }
        }
        XCTAssertNotCall("decodeRequestResponse(data:response:error:)", on: decoder)
    }

    func test_whenInRecoveryModeRecoveryRequestsShouldGoThrough() {
        apiClient.enterRecoveryMode()

        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)
        let lastRequestExpectation = expectation(description: "Last request completed")
        (1...5).forEach { index in
            let completionQueue: (Result<TestUser, Error>) -> Void = { _ in
                if index == 5 {
                    lastRequestExpectation.fulfill()
                }
            }
            self.apiClient.request(
                URLRequest(url: .unique()),
                isRecoveryOperation: true,
                completion: completionQueue
            )
        }

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTEnsureRequestsWereExecuted(times: 5)
    }

    func test_whenInRegularModeRecoveryRequestsShouldThrowAnAssert() {
        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)
        let Logger_Spy = Logger_Spy()
        Logger_Spy.injectMock()

        let lastRequestExpectation = expectation(description: "Last request completed")
        (1...5).forEach { index in
            let completionQueue: (Result<TestUser, Error>) -> Void = { _ in
                if index == 5 {
                    lastRequestExpectation.fulfill()
                }
            }
            self.apiClient.request(
                URLRequest(url: .unique()),
                isRecoveryOperation: true,
                completion: completionQueue
            )
        }

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertCall("decodeRequestResponse(data:response:error:)", on: decoder, times: 5)
        Logger_Spy.restoreLogger()
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
        let completionQueue: (Result<TestUser, Error>) -> Void = { _ in }
        (1...5).forEach { index in
            self.apiClient.request(URLRequest(url: .unique()), isRecoveryOperation: true) { result in
                completionQueue(result)
                testBlock(index)
            }
        }

        waitForExpectations(timeout: defaultTimeout, handler: nil)
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
            self.apiClient.request(URLRequest(url: .unique()), isRecoveryOperation: true) { result in
                results.append(result)
                if index == 5 {
                    lastRequestExpectation.fulfill()
                }
            }
        }

        wait(for: [tokenRefreshIsCalled3Times], timeout: defaultTimeout)

        // 3 tries, token failure was returned until now
        // -> 1 unique | 3 total
        XCTEnsureRequestsWereExecuted(times: 3)

        // From now on we will let it through
        let testUser = TestUser(name: "test")
        decoder.decodeRequestResponse = .success(testUser)

        complete3rdTokenRefresh()

        waitForExpectations(timeout: defaultTimeout, handler: nil)

        // Request 1: 3 token failures + 1 success = 4
        // Requests 2-5: 1 success each = 4
        // -> 5 unique | 8 total
        XCTEnsureRequestsWereExecuted(times: 8)
    }

    // MARK: - Unmanaged Requests

    func test_unmanagedRequest_noRecoveryNoTokenFetching_requestSucceeds() throws {
        try executeUnmanagedRequestThatSucceeds()
    }

    func test_unmanagedRequest_recoveryNoTokenFetching_requestSucceeds() throws {
        apiClient.enterRecoveryMode()
        try executeUnmanagedRequestThatSucceeds()
    }

    func test_unmanagedRequest_recoveryAndTokenFetching_requestSucceeds() throws {
        apiClient.enterRecoveryMode()
        apiClient.enterTokenFetchMode()
        try executeUnmanagedRequestThatSucceeds()
    }

    func test_unmanagedRequest_noRecoveryButInTokenFetching_requestSucceeds() throws {
        apiClient.enterTokenFetchMode()
        try executeUnmanagedRequestThatSucceeds()
    }

    func test_unmanagedRequest_retriesOnConnectionFailure() throws {
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        decoder.decodeRequestResponse = .failure(networkError)

        let expectation = self.expectation(description: "Request completes")
        
        let completion: (Result<TestUser, Error>) -> Void = { _ in
            expectation.fulfill()
        }
        
        apiClient.unmanagedRequest(URLRequest(url: .unique()), completion: completion)
        waitForExpectations(timeout: defaultTimeout, handler: nil)

        // Retries until the maximum amount
        XCTEnsureRequestsWereExecuted(times: 4)
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
            requestDecoder: decoder,
            attachmentUploader: attachmentUploader
        )
        apiClient.tokenRefresher = self.tokenRefresher
        apiClient.queueOfflineRequest = self.queueOfflineRequest
    }

    private func executeUnmanagedRequestThatSucceeds() throws {
        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())

        // Set up a successful mock network response for the request
        let user = TestUser(name: "Network Response")
        let mockNetworkResponseData = try JSONEncoder.stream.encode(user)
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 234, responseBody: mockNetworkResponseData)

        // Set up a decoder response
        // ⚠️ Watch out: the user is different there, so we can distinguish between the incoming data
        // to the encoder, and the outgoing data).
        let mockDecoderResponseData = TestUser(name: "Decoder Response")
        decoder.decodeRequestResponse = .success(mockDecoderResponseData)

        // Create a test endpoint (it's actually ignored, because APIClient uses the testRequest returned from the encoder)
        let testEndpoint = URLRequest(url: .unique())

        // Create a request and wait for the completion block
        let result: Result<TestUser, Error> = try waitFor {
            apiClient.unmanagedRequest(testEndpoint, completion: $0)
        }

        // Check the incoming data to the encoder is the URLResponse and data from the network
        XCTAssertEqual(result.value, mockDecoderResponseData)

        // Check the outgoing data from the encoder is the result data
        AssertResultSuccess(result, mockDecoderResponseData)
        XCTEnsureRequestsWereExecuted(times: 1)
    }

    // MARK: - Helpers

    func XCTEnsureRequestsWereExecuted(times: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertCall("decodeRequestResponse(data:response:error:)", on: decoder, times: times, file: file, line: line)
    }
}
