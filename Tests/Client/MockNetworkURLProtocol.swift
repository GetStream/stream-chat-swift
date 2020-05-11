//
//  MockNetworkURLProtocol.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import StreamChatClient

/// This URLProtocol intercepts the network communication and provides mock responses for the registered endpoints.
class MockNetworkURLProtocol: URLProtocol {

    private static var responses: [PathAndMethod: MockResponse] = [:]

    /// Cleans up all existing mock reponses.
    static func reset() {
        Self.responses.removeAll()
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard
            let path = request.url?.path.normalizedPath,
            let method = request.httpMethod
        else { return false }

        let key = PathAndMethod(path: path, method: method)
        return responses.keys.contains(key)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Overriding this function is required by the superclass.
        return request
    }

    // MARK: Instance methods

    override func startLoading() {
        guard
            let path = request.url?.path.normalizedPath,
            let method = request.httpMethod,
            let mockResponse = Self.responses[.init(path: path, method: method)]
        else {
            fatalError("This should never happen. Check if the implementation of the `canInit` method is correct.")
        }

        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: mockResponse.responseCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .allowed)

        switch mockResponse.result {
        case let .success(data):
            self.client?.urlProtocol(self, didLoad: data)
        case let .failure(error):
            self.client?.urlProtocol(self, didFailWithError: error)
        }

        // Finish loading (required).
        self.client?.urlProtocolDidFinishLoading(self)

        // Clean up
        DispatchQueue.main.async {
            Self.responses.removeValue(forKey: .init(path: path, method: method))
        }
    }

    override func stopLoading() {
        // Required by the superclass
    }
}

extension MockNetworkURLProtocol {

    /// Creates a successful mock response for the given endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint the mock response is registered for.
    ///   - statusCode: The HTTP status code used for the response.
    ///   - response: The JSON body of the response.
    static func mockResponse(endpoint: Endpoint, statusCode: Int = 200, responseBody: [String: Any] = [:]) {
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: responseBody, options: .prettyPrinted)
        } catch {
            fatalError("Error encoding mock responseBody to JSON: \(error)")
        }

        let key = PathAndMethod(path: endpoint.path.normalizedPath, method: endpoint.method.rawValue)
        Self.responses[key] = MockResponse(result: .success(jsonData), responseCode: statusCode)
    }

    /// Creates a failing mock response for the given endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint the mock response is registered for.
    ///   - statusCode: The HTTP status code used for the response.
    ///   - error: The error object used for the response.
    static func mockResponse(endpoint: Endpoint, statusCode: Int = 400, error: Error) {
        let key = PathAndMethod(path: endpoint.path.normalizedPath, method: endpoint.method.rawValue)

        Self.responses[key] = MockResponse(result: .failure(error), responseCode: statusCode)
    }
}

/// Used for using the combination of `path` and `httpMethod` as a dictionary key.
private struct PathAndMethod: Hashable {
    let path: String
    let method: String
}

private struct MockResponse {
    let result: Result<Data, Error>
    let responseCode: Int
}



private extension String {
    /// Removes all leading `/` from the string.
    var normalizedPath: String {
        String(drop(while: { $0 == "/"}))
    }
}
