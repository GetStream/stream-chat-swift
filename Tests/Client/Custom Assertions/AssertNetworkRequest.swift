//
//  AssertNetworkRequest.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient


extension Assert {
    /// Synchronously waits for a network request that matches its properties with the given parameters.
    ///
    /// The function periodically checks the `RequestRecorderURLProtocol.recordedRequests` and If no request matches the
    /// given parameters within the `timeout` period, this assertion fails with the time-out error.
    ///
    /// The values specified in the `headers`, `queryParameters` and `body` represents the mandatory subset of
    /// the values the request must have. A request is valid even when it contains additional parameters than
    /// the ones specified in these values.
    ///
    /// - Parameters:
    ///   - method: The HTTP method the request.
    ///   - path: The `path` part of the request's URL.
    ///   - headers: The headers required for the request.
    ///   - queryParameters: The query parameters required for the request.
    ///   - body: The expected body of the request.
    ///   - timeout: The maximum time this function waits for a request to match the given parameters.
    ///
    static func networkRequest(method: Endpoint.Method,
                               path: String,
                               headers: [String: String]?,
                               queryParameters: [String: String]?,
                               body: [String: Any]?,
                               timeout: TimeInterval = 0.5,
                               file: StaticString = #file,
                               line: UInt = #line) -> Assertion {
        
        return Assert.willBeTrue(RequestRecorderURLProtocol.recordedRequests.contains {
            $0.matches(method, path, headers, queryParameters, body)
        }, message: "Failed to find a matching request in the recorded request array")
    }
}

private extension URLRequest {
    /// Returns `true` if the given parameters match the current `URLRequest`. Otherwise returns `false`.
    func matches(_ method: Endpoint.Method,
                 _ path: String,
                 _ headers: [String: String]?,
                 _ queryParameters: [String: String]?,
                 _ body: [String: Any]?) -> Bool {
        
        // check method
        guard httpMethod == method.rawValue else { return false }
        
        // check path
        guard let url = self.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.path == path else { return false }
        
        // check headers
        let requestHeaders = allHTTPHeaderFields ?? [:]
        let expectedHeaders = headers ?? [:]
        guard expectedHeaders.allSatisfy({ key, value in
            requestHeaders[key] == value
        }) else { return false }
        
        // Check query parameters
        let items = components.queryItems ?? []
        let expectedQueryParameters = queryParameters ?? [:]
        guard expectedQueryParameters.allSatisfy({ key, value in
            items[key] == value
        }) else { return false }
        
        // Check the request body
        let requestBodyData = httpBodyStream.map({ Data(reading: $0) }) ?? httpBody
        guard let bodyData = requestBodyData else {
            // In case the current request body is not present then
            // the expected body should also not be present
            return body == nil
        }
        guard let assertingBody = body,
            let assertingBodyData =
                try? JSONSerialization.data(withJSONObject: assertingBody) else {
            
            // In case the serialized JSON is nil then the expected body should also be nil
            return body == nil
        }
        
        return isJSONEqual(assertingBodyData, bodyData)
    }
}

private extension Array where Element == URLQueryItem {
    /// Returns the value of the URLQueryItem with the given name. Returns `nil`
    /// if the query item doesn't exist.
    subscript(_ name: String) -> String? {
        first(where: { $0.name == name}).flatMap({ $0.value })
    }
}

private extension Data {
    /// Creates a new Data instance from the provided InputStream. It opens and closes the stream during the process.
    init(reading input: InputStream) {
        self.init()
        input.open()
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if (read == 0) {
                break  // added
            }
            append(buffer, count: read)
        }
        buffer.deallocate()
        input.close()
    }
}
