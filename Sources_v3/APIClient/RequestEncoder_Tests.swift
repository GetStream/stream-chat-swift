//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class RequestEncoder_Tests: XCTestCase {
    var encoder: RequestEncoder!
    var baseURL: URL!
    var apiKey: APIKey!
    fileprivate var connectionDetailsProvider: TestConnectionDetailsProviderDelegate!
    
    override func setUp() {
        super.setUp()
        
        apiKey = APIKey(.unique)
        baseURL = .unique()
        encoder = DefaultRequestEncoder(baseURL: baseURL, apiKey: apiKey)
        
        connectionDetailsProvider = TestConnectionDetailsProviderDelegate()
        encoder.connectionDetailsProviderDelegate = connectionDetailsProvider
    }
    
    func test_requiredQueryItems() throws {
        // Prepare a new endpoint
        let endpoint = Endpoint<Data>(
            path: .unique,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Encode the request and wait for the result
        let request = try await { encoder.encodeRequest(for: endpoint, completion: $0) }.get()
        
        // Check the required query item values are present
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponents.queryItems?["api_key"], apiKey.apiKeyString)
    }
    
    func test_requiredAuthHeaders() throws {
        // Prepare a new endpoint
        let endpoint = Endpoint<Data>(
            path: .unique,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Simulate provided token
        let token = Token.unique
        connectionDetailsProvider.token = token
        
        // Encode the request and wait for the result
        var request = try await { encoder.encodeRequest(for: endpoint, completion: $0) }.get()
        
        // Check the auth headers are present
        XCTAssertEqual(request.allHTTPHeaderFields?["Stream-Auth-Type"], "jwt")
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], token)
        
        // Simulate no token is provided
        connectionDetailsProvider.token = nil
        
        // Encode the request and wait for the result
        request = try await { encoder.encodeRequest(for: endpoint, completion: $0) }.get()
        
        // Check the auth headers
        XCTAssertEqual(request.allHTTPHeaderFields?["Stream-Auth-Type"], "anonymous")
    }
    
    func test_endpointRequiringConectionId() throws {
        // Prepare an endpoint that requires connection id
        let endpoint = Endpoint<Data>(
            path: .unique,
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            body: nil
        )
        
        // Set a new connection id
        let connectionId = String.unique
        connectionDetailsProvider.connectionId = connectionId
        
        // Encode the request and wait for the result
        let request = try await { encoder.encodeRequest(for: endpoint, completion: $0) }.get()
        
        // Check the connection id is set
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponents.queryItems?["connection_id"], connectionId)
    }
    
    func test_encodingRequestURL() throws {
        let testStringValue = String.unique
        
        // Prepare a request with query items
        let endpoint = Endpoint<Data>(
            path: .unique,
            method: .post,
            queryItems: ["stringValue": testStringValue],
            requiresConnectionId: false,
            body: nil
        )
        
        // Encode the request and wait for the result
        let request = try await { encoder.encodeRequest(for: endpoint, completion: $0) }.get()
        
        // Check the URL is set up correctly
        XCTAssertEqual(request.httpMethod, endpoint.method.rawValue)
        XCTAssertEqual(request.url?.scheme, baseURL.scheme)
        XCTAssertEqual(request.url?.host, baseURL.host)
        XCTAssertEqual(request.url?.path, "/" + endpoint.path)
        
        // Check custom query items
        let urlComponenets = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        XCTAssertEqual(urlComponenets.queryItems?["stringValue"], testStringValue)
    }
    
    func test_encodingRequestBody_POST() throws {
        // Prepare a POST endpoint with JSON body
        let endpoint = Endpoint<Data>(
            path: .unique,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: TestUser(name: "Luke", age: 22)
        )
        
        // Encode the request and wait for the result
        let request = try await { encoder.encodeRequest(for: endpoint, completion: $0) }.get()
        
        // Check the body is present
        let body = try XCTUnwrap(request.httpBody)
        let serializedBody = try JSONDecoder.stream.decode(TestUser.self, from: body)
        
        XCTAssertEqual(serializedBody, endpoint.body as! TestUser)
    }
    
    func test_encodingRequestBody_GET() throws {
        // Prepare a GET endpoint with JSON body
        let endpoint = Endpoint<Data>(
            path: .unique,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "user1": TestUser(name: "Luke", age: 22),
                "user2": TestUser(name: "Leia", age: 22)
            ]
        )
        
        // Encode the request and wait for the result
        let request = try await { encoder.encodeRequest(for: endpoint, completion: $0) }.get()
        
        // Check both JSONs are present in the query items
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        
        let user1String = try XCTUnwrap(urlComponents.queryItems?["user1"])
        let user1JSON = try JSONDecoder.default.decode(TestUser.self, from: user1String.data(using: .utf8)!)
        XCTAssertEqual(user1JSON, TestUser(name: "Luke", age: 22))
        
        let user2String = try XCTUnwrap(urlComponents.queryItems?["user2"])
        let user2JSON = try JSONDecoder.default.decode(TestUser.self, from: user2String.data(using: .utf8)!)
        XCTAssertEqual(user2JSON, TestUser(name: "Leia", age: 22))
    }
    
    func test_encodingGETRequestBody_withQueryItems() throws {
        // Prepare a GET endpoint with both, the query items and JSON body
        let endpoint = Endpoint<Data>(
            path: .unique,
            method: .get,
            queryItems: ["father": "Anakin"],
            requiresConnectionId: false,
            body: ["user": TestUser(name: "Luke", age: 22)]
        )
        
        // Encode the request and wait for the result
        let request = try await { encoder.encodeRequest(for: endpoint, completion: $0) }.get()
        
        let urlComponents = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        
        // Check the query item
        XCTAssertEqual(urlComponents.queryItems?["father"], "Anakin")
        
        // Check the query-item encoded body
        let userString = try XCTUnwrap(urlComponents.queryItems?["user"])
        let userJSON = try JSONDecoder.default.decode(TestUser.self, from: userString.data(using: .utf8)!)
        XCTAssertEqual(userJSON, TestUser(name: "Luke", age: 22))
    }
}

class TestConnectionDetailsProviderDelegate: ConnectionDetailsProviderDelegate {
    var token: Token?
    
    var connectionId: ConnectionId?
    var connectionWaiters: [(ConnectionId?) -> Void] = []
    
    func provideConnectionId(completion: @escaping (ConnectionId?) -> Void) {
        connectionWaiters.append(completion)
        if let connectionId = connectionId {
            completion(connectionId)
        }
    }
    
    func provideToken() -> Token? { token }
}

private struct TestUser: Codable, Equatable {
    let name: String
    let age: Int
}

extension Array where Element == URLQueryItem {
    /// Returns the value of the URLQueryItem with the given name. Returns `nil` if the query item doesn't exist.
    subscript(_ name: String) -> String? {
        first(where: { $0.name == name }).flatMap(\.value)
    }
}
