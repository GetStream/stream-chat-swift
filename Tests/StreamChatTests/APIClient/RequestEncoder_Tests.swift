//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RequestEncoder_Tests: XCTestCase {
    var encoder: RequestEncoder!
    var baseURL: URL!
    var apiKey: APIKey!
    fileprivate var connectionDetailsProvider: ConnectionDetailsProviderDelegate_Spy!

    override func setUp() {
        super.setUp()

        apiKey = APIKey(.unique)
        baseURL = .unique()
        encoder = DefaultRequestEncoder(baseURL: baseURL, apiKey: apiKey)

        connectionDetailsProvider = ConnectionDetailsProviderDelegate_Spy()
        encoder.connectionDetailsProviderDelegate = connectionDetailsProvider

        VirtualTimeTimer.time = VirtualTime()
    }

    override func tearDown() {
        encoder = nil
        baseURL = nil
        apiKey = nil
        connectionDetailsProvider = nil
        VirtualTimeTimer.invalidate()

        super.tearDown()
    }

    func test_endpointRequiringToken_hasCorrectHeaders_ifTokenIsProvided() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Simulate provided token
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: false,
                requiresToken: true,
                completion: $0
            )
        }.get()

        // Check the auth headers are present
        XCTAssertEqual(request.allHTTPHeaderFields?["Stream-Auth-Type"], "jwt")
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], token.rawValue)
    }

    func test_endpointRequiringToken_hasCorrectHeaders_ifAnonymousTokenIsProvided() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Set anonymous token.
        connectionDetailsProvider.provideTokenResult = .success(.anonymous)

        // Encode the request and wait for the result.
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: false,
                requiresToken: true,
                completion: $0
            )
        }.get()

        // Check the anonymous auth header is set.
        XCTAssertEqual(request.allHTTPHeaderFields?["Stream-Auth-Type"], "anonymous")
    }

    func test_endpointRequiringToken_isCancelled_ifNilTokenIsProvided() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Reset the token.
        connectionDetailsProvider.provideTokenResult = nil

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encode(
            request: initialRequest,
            requiresConnectionId: false,
            requiresToken: true
        ) { encodingResult = $0 }

        // Cancel all token waiting requests.
        connectionDetailsProvider.completeTokenWaiters(passing: nil)

        // Assert request encoding has failed.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.MissingToken)
    }

    func test_endpointRequiringToken_whenTokenProviderTimeouts_returnsCorrectError() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Reset the token.
        connectionDetailsProvider.provideTokenResult = .failure(ClientError.WaiterTimeout())

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encode(
            request: initialRequest,
            requiresConnectionId: false,
            requiresToken: true
        ) { encodingResult = $0 }

        // Assert request encoding has failed with the correct error.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.WaiterTimeout)
    }

    func test_endpointRequiringToken_whenTokenProviderFailsWithUnknownError_returnsMissingTokenError() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Reset the token.
        connectionDetailsProvider.provideTokenResult = .failure(TestError())

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encode(
            request: initialRequest,
            requiresConnectionId: false,
            requiresToken: true
        ) { encodingResult = $0 }

        // Assert request encoding has failed with the correct error.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.MissingToken)
    }

    func test_endpointRequiringConnectionId_hasCorrectQueryItems_ifConnectionIdIsProvided() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Set a new connection id
        let connectionId = String.unique
        connectionDetailsProvider.provideConnectionIdResult = .success(connectionId)

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: true,
                requiresToken: false,
                completion: $0
            )
        }.get()

        // Check the connection id is set
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponents.queryItems?["connection_id"], connectionId)
    }

    func test_endpointRequiringConnectionId_isCanceled_ifNilConnectionIdIsProvided() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Reset a connection id
        connectionDetailsProvider.provideConnectionIdResult = nil

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encode(
            request: initialRequest,
            requiresConnectionId: true,
            requiresToken: false
        ) { encodingResult = $0 }

        // Cancel all connection id waiting requests.
        connectionDetailsProvider.completeConnectionIdWaiters(passing: nil)

        // Assert request encoding has failed.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.MissingConnectionId)
    }

    func test_endpointRequiringConnectionId_whenConnectionIdProviderTimeouts_returnsCorrectError() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Reset the token.
        connectionDetailsProvider.provideConnectionIdResult = .failure(ClientError.WaiterTimeout())

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encode(
            request: initialRequest,
            requiresConnectionId: true,
            requiresToken: false
        ) { encodingResult = $0 }

        // Assert request encoding has failed with the correct error.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.WaiterTimeout)
    }

    func test_endpointRequiringConnectionId_whenConnectionIdFailsWithUnknownError_returnsMissingConnectionIdError() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Reset the token.
        connectionDetailsProvider.provideConnectionIdResult = .failure(TestError())

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encode(
            request: initialRequest,
            requiresConnectionId: true,
            requiresToken: false
        ) { encodingResult = $0 }

        // Assert request encoding has failed with the correct error.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.MissingConnectionId)
    }

    func test_endpointRequiringConnectionIdAndToken_isEncodedCorrectly_ifBothAreProvided() throws {
        // Prepare a new request
        let initialRequest = URLRequest(url: .unique())

        // Set a new connection id
        let connectionId = String.unique
        connectionDetailsProvider.provideConnectionIdResult = .success(connectionId)

        // Set a new token
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: true,
                requiresToken: true,
                completion: $0
            )
        }.get()

        // Check the connection id is set
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponents.queryItems?["connection_id"], connectionId)
        // Check the auth headers are set.
        XCTAssertEqual(request.allHTTPHeaderFields?["Stream-Auth-Type"], "jwt")
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], token.rawValue)
    }

    func test_encodingRequestURL() throws {
        let testStringValue = String.unique

        // Prepare a request with query items
        var components = URLComponents(url: .unique(), resolvingAgainstBaseURL: true)!
        components.queryItems = [.init(name: "stringValue", value: testStringValue)]
        var urlRequest = URLRequest(url: components.url ?? .unique())
        urlRequest.httpMethod = "POST"

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: urlRequest,
                requiresConnectionId: false,
                requiresToken: false,
                completion: $0
            )
        }.get()

        // Check the URL is set up correctly
        XCTAssertEqual(request.httpMethod, urlRequest.httpMethod)
        XCTAssertEqual(request.url?.scheme, baseURL.scheme)
        XCTAssertEqual(request.url?.host, urlRequest.url?.host)
        XCTAssertEqual(request.url?.port, baseURL.port)
        XCTAssertEqual(request.url?.path, urlRequest.url!.relativePath)

        // Check custom query items
        let urlComponenets = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponenets.queryItems?["stringValue"], testStringValue)
    }

    func test_encodingRequestBody_POST() throws {
        // Prepare a POST endpoint with JSON body
        let testUser = TestUser(name: "Luke", age: 22)
        var initialRequest = URLRequest(url: .unique())
        initialRequest.httpBody = try JSONEncoder.default.encode(testUser)
        initialRequest.httpMethod = "POST"

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: false,
                requiresToken: false,
                completion: $0
            )
        }.get()

        // Check the body is present
        let body = try XCTUnwrap(request.httpBody)
        let serializedBody = try JSONDecoder.stream.decode(TestUser.self, from: body)

        XCTAssertEqual(serializedBody, testUser)
    }

    func test_encodingRequestBodyAsData_POST() throws {
        // Prepare a POST endpoint with JSON body
        let bodyAsData = try JSONEncoder.stream.encode(TestUser(name: "Luke", age: 22))
        var initialRequest = URLRequest(url: .unique())
        initialRequest.httpBody = bodyAsData
        initialRequest.httpMethod = "POST"

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: false,
                requiresToken: false,
                completion: $0
            )
        }.get()

        // Check the body is sent as is
        let sentBody = try XCTUnwrap(request.httpBody)
        XCTAssertEqual(sentBody, bodyAsData)
    }

    func test_encodingRequestWithoutBody_POST() throws {
        // Our backend expects all POST requests will have a body, even if empty
        // nil body is not acceptable (causes invalid json - 400 error)

        // Prepare a POST endpoint without JSON body
        var initialRequest = URLRequest(url: .unique())
        initialRequest.httpMethod = "POST"

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: false,
                requiresToken: false,
                completion: $0
            )
        }.get()

        // Check the body is nil
        XCTAssertNil(request.httpBody)
    }

    func test_encodingRequestBody_PATCH() throws {
        // Prepare a PATCH endpoint with JSON body
        let testUser = TestUser(name: "Luke", age: 22)
        let bodyAsData = try JSONEncoder.stream.encode(testUser)
        var initialRequest = URLRequest(url: .unique())
        initialRequest.httpBody = bodyAsData
        initialRequest.httpMethod = "PATCH"

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: false,
                requiresToken: false,
                completion: $0
            )
        }.get()

        // Check the body is present
        let body = try XCTUnwrap(request.httpBody)
        let serializedBody = try JSONDecoder.stream.decode(TestUser.self, from: body)

        XCTAssertEqual(serializedBody, testUser)
    }

    func test_encodingRequestBodyAsData_PATCH() throws {
        // Prepare a PATCH endpoint with JSON body
        let bodyAsData = try JSONEncoder.stream.encode(TestUser(name: "Luke", age: 22))

        var initialRequest = URLRequest(url: .unique())
        initialRequest.httpBody = bodyAsData
        initialRequest.httpMethod = "PATCH"

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: false,
                requiresToken: false,
                completion: $0
            )
        }.get()

        // Check the body is present
        let sentBody = try XCTUnwrap(request.httpBody)
        XCTAssertEqual(sentBody, bodyAsData)
    }

    func test_encodingRequestWithoutBody_PATCH() throws {
        // Prepare a PATCH endpoint without JSON body
        var initialRequest = URLRequest(url: .unique())
        initialRequest.httpMethod = "PATCH"

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: initialRequest,
                requiresConnectionId: false,
                requiresToken: false,
                completion: $0
            )
        }.get()

        // Check the body is nil
        XCTAssertNil(request.httpBody)
    }

    func test_encodingGETRequestBody_withQueryItems() throws {
        // Prepare a GET endpoint with both, the query items and JSON body
        var components = URLComponents(url: .unique(), resolvingAgainstBaseURL: true)!
        components.queryItems = [.init(name: "father", value: "Anakin")]
        let urlRequest = URLRequest(url: components.url ?? .unique())

        // Encode the request and wait for the result
        let request = try waitFor {
            encoder.encode(
                request: urlRequest,
                requiresConnectionId: false,
                requiresToken: false,
                completion: $0
            )
        }.get()

        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))

        // Check the query item
        XCTAssertEqual(urlComponents.queryItems?["father"], "Anakin")
    }
}
