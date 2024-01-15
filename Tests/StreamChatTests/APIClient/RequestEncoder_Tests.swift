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

    func test_requiredQueryItems() throws {
        // Prepare a new endpoint
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: nil
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the required query item values are present
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponents.queryItems?["api_key"], apiKey.apiKeyString)
    }

    func test_endpointRequiringToken_hasCorrectHeaders_ifTokenIsProvided() throws {
        // Prepare a new endpoint
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            requiresConnectionId: false,
            requiresToken: true
        )

        // Simulate provided token
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the auth headers are present
        XCTAssertEqual(request.allHTTPHeaderFields?["Stream-Auth-Type"], "jwt")
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], token.rawValue)
    }

    func test_endpointRequiringToken_hasCorrectHeaders_ifAnonymousTokenIsProvided() throws {
        // Prepare a new endpoint
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            requiresConnectionId: false,
            requiresToken: true
        )

        // Set anonymous token.
        connectionDetailsProvider.provideTokenResult = .success(.anonymous)

        // Encode the request and wait for the result.
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the anonymous auth header is set.
        XCTAssertEqual(request.allHTTPHeaderFields?["Stream-Auth-Type"], "anonymous")
    }

    func test_endpointRequiringToken_isCancelled_ifNilTokenIsProvided() throws {
        // Prepare a new endpoint.
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            requiresConnectionId: false,
            requiresToken: true
        )

        // Reset the token.
        connectionDetailsProvider.provideTokenResult = nil

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encodeRequest(for: endpoint) { encodingResult = $0 }

        // Cancel all token waiting requests.
        connectionDetailsProvider.completeTokenWaiters(passing: nil)

        // Assert request encoding has failed.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.MissingToken)
    }

    func test_endpointRequiringToken_whenTokenProviderTimeouts_returnsCorrectError() throws {
        // Prepare a new endpoint.
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            requiresConnectionId: false,
            requiresToken: true
        )

        // Reset the token.
        connectionDetailsProvider.provideTokenResult = .failure(ClientError.WaiterTimeout())

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encodeRequest(for: endpoint) { encodingResult = $0 }

        // Assert request encoding has failed with the correct error.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.WaiterTimeout)
    }

    func test_endpointRequiringToken_whenTokenProviderFailsWithUnknownError_returnsMissingTokenError() throws {
        // Prepare a new endpoint.
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            requiresConnectionId: false,
            requiresToken: true
        )

        // Reset the token.
        connectionDetailsProvider.provideTokenResult = .failure(TestError())

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encodeRequest(for: endpoint) { encodingResult = $0 }

        // Assert request encoding has failed with the correct error.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.MissingToken)
    }

    func test_endpointRequiringConnectionId_hasCorrectQueryItems_ifConnectionIdIsProvided() throws {
        // Prepare an endpoint that requires connection id
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: false,
            body: nil
        )

        // Set a new connection id
        let connectionId = String.unique
        connectionDetailsProvider.provideConnectionIdResult = .success(connectionId)

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the connection id is set
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponents.queryItems?["connection_id"], connectionId)
    }

    func test_endpointRequiringConnectionId_isCanceled_ifNilConnectionIdIsProvided() throws {
        // Prepare an endpoint that requires connection id
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: false,
            body: nil
        )

        // Reset a connection id
        connectionDetailsProvider.provideConnectionIdResult = nil

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encodeRequest(for: endpoint) { encodingResult = $0 }

        // Cancel all connection id waiting requests.
        connectionDetailsProvider.completeConnectionIdWaiters(passing: nil)

        // Assert request encoding has failed.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.MissingConnectionId)
    }

    func test_endpointRequiringConnectionId_whenConnectionIdProviderTimeouts_returnsCorrectError() throws {
        // Prepare an endpoint that requires connection id
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: false,
            body: nil
        )

        // Reset the token.
        connectionDetailsProvider.provideConnectionIdResult = .failure(ClientError.WaiterTimeout())

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encodeRequest(for: endpoint) { encodingResult = $0 }

        // Assert request encoding has failed with the correct error.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.WaiterTimeout)
    }

    func test_endpointRequiringConnectionId_whenConnectionIdFailsWithUnknownError_returnsMissingConnectionIdError() throws {
        // Prepare an endpoint that requires connection id
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: false,
            body: nil
        )

        // Reset the token.
        connectionDetailsProvider.provideConnectionIdResult = .failure(TestError())

        // Encode the request and capture the result
        var encodingResult: Result<URLRequest, Error>?
        encoder.encodeRequest(for: endpoint) { encodingResult = $0 }

        // Assert request encoding has failed with the correct error.
        AssertAsync.willBeTrue(encodingResult?.error is ClientError.MissingConnectionId)
    }

    func test_endpointRequiringConnectionIdAndToken_isEncodedCorrectly_ifBothAreProvided() throws {
        // Prepare an endpoint that requires connection id
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: true,
            body: nil
        )

        // Set a new connection id
        let connectionId = String.unique
        connectionDetailsProvider.provideConnectionIdResult = .success(connectionId)

        // Set a new token
        let token = Token.unique()
        connectionDetailsProvider.provideTokenResult = .success(token)

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the connection id is set
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponents.queryItems?["connection_id"], connectionId)
        // Check the auth headers are set.
        XCTAssertEqual(request.allHTTPHeaderFields?["Stream-Auth-Type"], "jwt")
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], token.rawValue)
    }

    func test_encodeRequest_syncVersion_whenEndpointRequiresConnectionId_shouldReturnRequest() {
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: false,
            body: nil
        )

        connectionDetailsProvider.provideConnectionIdResult = .success(.unique)

        XCTAssertNoThrow(try encoder.encodeRequest(for: endpoint))
    }

    func test_encodeRequest_syncVersion_whenEndpointRequiresConnectionId_whenConnectionFails_shouldThrow() {
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: false,
            body: nil
        )

        connectionDetailsProvider.provideConnectionIdResult = .failure(TestError())
        
        XCTAssertThrowsError(try encoder.encodeRequest(for: endpoint))
    }

    func test_encodingRequestURL() throws {
        let testStringValue = String.unique

        // Prepare a request with query items
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .post,
            queryItems: ["stringValue": testStringValue],
            requiresConnectionId: false,
            requiresToken: false,
            body: nil
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the URL is set up correctly
        XCTAssertEqual(request.httpMethod, endpoint.method.rawValue)
        XCTAssertEqual(request.url?.scheme, baseURL.scheme)
        XCTAssertEqual(request.url?.host, baseURL.host)
        XCTAssertEqual(request.url?.port, baseURL.port)
        XCTAssertEqual(request.url?.path, "/" + endpoint.path.value)

        // Check custom query items
        let urlComponenets = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponenets.queryItems?["stringValue"], testStringValue)
    }

    func test_encodingRequestBody_POST() throws {
        // Prepare a POST endpoint with JSON body
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: TestUser(name: "Luke", age: 22)
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the body is present
        let body = try XCTUnwrap(request.httpBody)
        let serializedBody = try JSONDecoder.stream.decode(TestUser.self, from: body)

        XCTAssertEqual(serializedBody, endpoint.body as! TestUser)
    }

    func test_encodingRequestBodyAsData_POST() throws {
        // Prepare a POST endpoint with JSON body
        let bodyAsData = try JSONEncoder.stream.encode(TestUser(name: "Luke", age: 22))

        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: bodyAsData
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the body is sent as is
        let sentBody = try XCTUnwrap(request.httpBody)
        XCTAssertEqual(sentBody, bodyAsData)
    }

    func test_encodingRequestWithoutBody_POST() throws {
        // Our backend expects all POST requests will have a body, even if empty
        // nil body is not acceptable (causes invalid json - 400 error)

        // Prepare a POST endpoint with JSON body
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: nil
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the body is present (and empty)
        let body = try XCTUnwrap(request.httpBody)
        let serializedBody = try JSONDecoder.stream.decode(EmptyBody.self, from: body)

        XCTAssertEqual(serializedBody, EmptyBody())
    }

    func test_encodingRequestBody_PATCH() throws {
        // Prepare a PATCH endpoint with JSON body
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: TestUser(name: "Luke", age: 22)
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the body is present
        let body = try XCTUnwrap(request.httpBody)
        let serializedBody = try JSONDecoder.stream.decode(TestUser.self, from: body)

        XCTAssertEqual(serializedBody, endpoint.body as! TestUser)
    }

    func test_encodingRequestBodyAsData_PATCH() throws {
        // Prepare a PATCH endpoint with JSON body
        let bodyAsData = try JSONEncoder.stream.encode(TestUser(name: "Luke", age: 22))

        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: bodyAsData
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the body is present
        let sentBody = try XCTUnwrap(request.httpBody)
        XCTAssertEqual(sentBody, bodyAsData)
    }

    func test_encodingRequestWithoutBody_PATCH() throws {
        // Prepare a PATCH endpoint without JSON body
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: nil
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check the body is present (and empty)
        let body = try XCTUnwrap(request.httpBody)
        let serializedBody = try JSONDecoder.stream.decode(EmptyBody.self, from: body)

        XCTAssertEqual(serializedBody, EmptyBody())
    }

    func test_encodingRequestBody_GET() throws {
        // Prepare a GET endpoint with JSON body
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: [
                "user1": TestUser(name: "Luke", age: 22),
                // Test non-alphanumeric characters, too
                "user2": TestUser(name: "Leia is the best! + ♥️", age: 22)
            ]
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check both JSONs are present in the query items
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))

        let user1String = try XCTUnwrap(urlComponents.queryItems?["user1"])
        let user1JSON = try JSONDecoder.default.decode(TestUser.self, from: user1String.data(using: .utf8)!)
        XCTAssertEqual(user1JSON, TestUser(name: "Luke", age: 22))

        let user2String = try XCTUnwrap(urlComponents.queryItems?["user2"])
        let user2JSON = try JSONDecoder.default.decode(TestUser.self, from: user2String.data(using: .utf8)!)
        XCTAssertEqual(user2JSON, TestUser(name: "Leia is the best! + ♥️", age: 22))

        // Check the + sign is encoded properly in the query
        XCTAssertFalse(urlComponents.url!.query!.contains("+"))
        XCTAssertTrue(urlComponents.url!.query!.contains("%2B"))
    }

    func test_encodingRequestBodyAsData_GET() throws {
        // Prepare a GET endpoint with Data body
        let bodyAsData = try JSONEncoder.stream.encode([
            "user1": TestUser(name: "Luke", age: 22),
            // Test non-alphanumeric characters, too
            "user2": TestUser(name: "Leia is the best! + ♥️", age: 22)
        ])
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: bodyAsData
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        // Check both JSONs are present in the query items
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))

        let user1String = try XCTUnwrap(urlComponents.queryItems?["user1"])
        let user1JSON = try JSONDecoder.default.decode(TestUser.self, from: user1String.data(using: .utf8)!)
        XCTAssertEqual(user1JSON, TestUser(name: "Luke", age: 22))

        let user2String = try XCTUnwrap(urlComponents.queryItems?["user2"])
        let user2JSON = try JSONDecoder.default.decode(TestUser.self, from: user2String.data(using: .utf8)!)
        XCTAssertEqual(user2JSON, TestUser(name: "Leia is the best! + ♥️", age: 22))

        // Check the + sign is encoded properly in the query
        XCTAssertFalse(urlComponents.url!.query!.contains("+"))
        XCTAssertTrue(urlComponents.url!.query!.contains("%2B"))
    }

    func test_encodingGETRequestBody_withQueryItems() throws {
        // Prepare a GET endpoint with both, the query items and JSON body
        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: ["father": "Anakin"],
            requiresConnectionId: false,
            requiresToken: false,
            body: ["user": TestUser(name: "Luke", age: 22)]
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))

        // Check the query item
        XCTAssertEqual(urlComponents.queryItems?["father"], "Anakin")

        // Check the query-item encoded body
        let userString = try XCTUnwrap(urlComponents.queryItems?["user"])
        let userJSON = try JSONDecoder.default.decode(TestUser.self, from: userString.data(using: .utf8)!)
        XCTAssertEqual(userJSON, TestUser(name: "Luke", age: 22))
    }

    func test_encodingGETRequestBodyAsData_withQueryItemsAsData() throws {
        // Prepare a GET endpoint with both, the query items and body as Data
        let queryItemsData = try JSONEncoder.stream.encode(["father": "Anakin"])
        let bodyAsData = try JSONEncoder.stream.encode(["user": TestUser(name: "Luke", age: 22)])

        let endpoint = Endpoint<Data>(
            path: .guest,
            method: .get,
            queryItems: queryItemsData,
            requiresConnectionId: false,
            requiresToken: false,
            body: bodyAsData
        )

        // Encode the request and wait for the result
        let request = try waitFor { encoder.encodeRequest(for: endpoint, completion: $0) }.get()

        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))

        // Check the query item
        XCTAssertEqual(urlComponents.queryItems?["father"], "Anakin")

        // Check the query-item encoded body
        let userString = try XCTUnwrap(urlComponents.queryItems?["user"])
        let userJSON = try JSONDecoder.default.decode(TestUser.self, from: userString.data(using: .utf8)!)
        XCTAssertEqual(userJSON, TestUser(name: "Luke", age: 22))
    }
}
