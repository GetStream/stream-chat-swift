//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class APIClient_Tests: StressTestCase {
    var apiClient: APIClient!
    
    var apiKey: APIKey!
    var baseURL: URL!
    var sessionConfiguration: URLSessionConfiguration!
    
    var uniqeHeaderValue: String!
    
    var encoder: TestRequestEncoder!
    var decoder: TestRequestDecoder!
    var cdnClient: CDNClient_Mock!
    
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
        uniqeHeaderValue = .unique
        sessionConfiguration.httpAdditionalHeaders?["unique_value"] = uniqeHeaderValue
        
        encoder = TestRequestEncoder(baseURL: baseURL, apiKey: apiKey)
        decoder = TestRequestDecoder()
        cdnClient = CDNClient_Mock()
        cdnClient.uploadAttachmentMockFunc.returns(())
        
        apiClient = APIClient(
            sessionConfiguration: sessionConfiguration,
            requestEncoder: encoder,
            requestDecoder: decoder,
            CDNClient: cdnClient
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
        let result = try waitFor { apiClient.request(endpoint: testEndpoint, completion: $0) }
        AssertResultFailure(result, testError)
    }

    // MARK: - Networking
    
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
        apiClient.request(endpoint: testEndpoint) { _ in }
        
        // Check a network request is made with the values from `testRequest`
        AssertNetworkRequest(
            method: .post,
            path: "/" + uniquePath,
            // the "name" header value comes from the request, "unique_value" from the session config
            headers: ["surname": "Organa", "unique_value": uniqeHeaderValue],
            queryParameters: ["item": uniqueQueryItem],
            body: try JSONEncoder().encode(["name": "Leia"])
        )
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
        let result = try waitFor { apiClient.request(endpoint: testEndpoint, completion: $0) }
        
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
        assert(decoder.decodeRequestResponse_error != nil)
        
        // We have to compare error codes, since iOS14 wraps network errors into `NSURLError`
        // in which we cannot retrieve the wrapper error
        XCTAssertEqual((decoder.decodeRequestResponse_error as NSError?)?.code, networkError.code)
        
        // Check the outgoing error from the encoder is the result data
        AssertResultFailure(result, encoderError)
    }
    
    func test_uploadAttachment_calls_CDNClient() throws {
        let attachment = AnyChatMessageAttachment.sample()
        
        var progress: Double?
        var result: Result<URL, Error>?
        
        apiClient.uploadAttachment(
            attachment,
            progress: { progress = $0 },
            completion: { result = $0 }
        )
        
        XCTAssertTrue(cdnClient.uploadAttachmentMockFunc.called)
        
        let parameters = try XCTUnwrap(cdnClient.uploadAttachmentMockFunc.calls.last)
        
        let sampleProgress: Double = 42
        parameters.1?(sampleProgress)
        XCTAssertEqual(progress, sampleProgress)
        
        let imageURL = URL.localYodaImage
        parameters.2(.success(imageURL))
        XCTAssertEqual(try result?.get(), imageURL)
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
    
    weak var connectionDetailsProviderDelegate: ConnectionDetailsProviderDelegate?
    
    var encodeRequest: Result<URLRequest, Error>? = .success(URLRequest(url: .unique()))
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
            log.warning("TestRequestDecoder simulated response not set. Throwing a TestError.")
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
    let path: String
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
        lhs.path == rhs.path
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
