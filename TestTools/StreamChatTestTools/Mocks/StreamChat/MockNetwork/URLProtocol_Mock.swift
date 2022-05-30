//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import StreamChat

/// This URLProtocol intercepts the network communication and provides mock responses for the registered endpoints.
final class URLProtocol_Mock: URLProtocol {
    static let testSessionHeaderKey = "URLProtocolMock_test_session_id"
    
    /// Starts a new recording session. Adds a unique identifier to the configuration headers and listens only
    /// for the request with this id.
    static func startTestSession(with configuration: inout URLSessionConfiguration) {
        reset()
        let newSessionId = UUID().uuidString
        currentSessionId = newSessionId
        
        // URLProtocol_Mock always has to be first, but not if the RequestRecorderURLProtocol_Mock is presented
        if let recorderProtocolIdx = configuration.protocolClasses?
            .firstIndex(where: { $0 is RequestRecorderURLProtocol_Mock.Type }) {
            configuration.protocolClasses?.insert(Self.self, at: recorderProtocolIdx + 1)
        } else {
            configuration.protocolClasses?.insert(Self.self, at: 0)
        }
        
        var existingHeaders = configuration.httpAdditionalHeaders ?? [:]
        existingHeaders[Self.testSessionHeaderKey] = newSessionId
        configuration.httpAdditionalHeaders = existingHeaders
    }
    
    @Atomic private static var responses: [PathAndMethod: MockResponse] = [:]
    
    /// If set, the mock protocol responds to requests with `testSessionHeaderKey` header value set to this value. If `nil`,
    /// all requests are ignored.
    @Atomic static var currentSessionId: String?
    
    /// Cleans up all existing mock responses and current test session id.
    static func reset() {
        Self.currentSessionId = nil
        Self.responses.removeAll()
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard
            request.value(forHTTPHeaderField: testSessionHeaderKey) == currentSessionId,
            let url = request.url,
            let method = request.httpMethod
        else { return false }
        
        let key = PathAndMethod(url: url, method: method)
        return responses.keys.contains(key)
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Overriding this function is required by the superclass.
        request
    }
    
    // MARK: Instance methods
    
    override func startLoading() {
        guard
            let url = request.url,
            let method = request.httpMethod,
            let mockResponse = Self.responses[.init(url: url, method: method)]
        else {
            fatalError("This should never happen. Check if the implementation of the `canInit` method is correct.")
        }
        
        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: mockResponse.responseCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .allowed)
        
        switch mockResponse.result {
        case let .success(data):
            client?.urlProtocol(self, didLoad: data)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        // Finish loading (required).
        client?.urlProtocolDidFinishLoading(self)
        
        // Clean up
        Self._responses.mutate {
            $0.removeValue(forKey: .init(url: url, method: method))
        }
    }
    
    override func stopLoading() {
        // Required by the superclass
    }
}

extension URLProtocol_Mock {
    /// Creates a successful mock response for the given endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint the mock response is registered for.
    ///   - statusCode: The HTTP status code used for the response.
    ///   - response: The JSON body of the response.
    static func mockResponse(request: URLRequest, statusCode: Int = 200, responseBody: Data = Data([])) {
        let key = PathAndMethod(url: request.url!, method: request.httpMethod!)
        Self._responses.mutate {
            $0[key] = MockResponse(result: .success(responseBody), responseCode: statusCode)
        }
    }
    
    /// Creates a failing mock response for the given endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint the mock response is registered for.
    ///   - statusCode: The HTTP status code used for the response.
    ///   - error: The error object used for the response.
    static func mockResponse(request: URLRequest, statusCode: Int = 400, error: Error) {
        let key = PathAndMethod(url: request.url!, method: request.httpMethod!)
        Self._responses.mutate {
            $0[key] = MockResponse(result: .failure(error), responseCode: statusCode)
        }
    }
}

/// Used for using the combination of `path` and `httpMethod` as a dictionary key.
private struct PathAndMethod: Hashable {
    let url: URL
    let method: String
}

private struct MockResponse {
    let result: Result<Data, Error>
    let responseCode: Int
}

private extension String {
    /// Removes all leading `/` from the string.
    var normalizedPath: String {
        String(drop(while: { $0 == "/" }))
    }
}
