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
            $0.matches(method, path, headers, queryParameters, body).isSuccess
        }, message: "Failed to find a matching request in the recorded request list:\n" +
            RequestRecorderURLProtocol.recordedRequests.map { $0.description }.joined(separator: "\n"),
           file: file,
           line: line)
    }
}

private extension URLRequest {
    enum MatchResult {
        case success
        case failure(String)
        
        static func from(_ message: String) -> MatchResult {
            message.isEmpty ? .success : .failure(message)
        }
        
        var isSuccess: Bool {
            switch self {
            case .success: return true
            default: return false
            }
        }
    }
    
    var description: String {
        guard let url = self.url else { return "" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        
        return "URLRequest:\n" +
            "url=\(url.absoluteString)\n" +
            "method=\(httpMethod ?? "")\n" +
            "headers=\(allHTTPHeaderFields ?? [:])\n" +
            "queryItems=\(String(describing: queryItems))\n\n"
    }
    
    /// Returns `true` if the given parameters match the current `URLRequest`. Otherwise returns `false`.
    func matches(_ method: Endpoint.Method,
                 _ path: String,
                 _ headers: [String: String]?,
                 _ queryParameters: [String: String]?,
                 _ body: [String: Any]?) -> MatchResult {
        
        var errorMessage = ""
        
        // check method
        if httpMethod != method.rawValue {
            errorMessage += "\n  - Incorrect method: expected \"\(method.rawValue)\""
            errorMessage +=  " got \"\(httpMethod ?? "_")\""
        }
        
        // check path
        guard let url = self.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            errorMessage += "\n  - Missing URL"
            return .failure(errorMessage)
        }
        
        // Check path
        if components.path != path {
            errorMessage += "\n  - Incorrect path: expected \"\(path)\" got \"\(components.path)\""
        }
        
        // Check headers
        let requestHeaders = allHTTPHeaderFields ?? [:]
        headers?.forEach { (key, value) in
            if let requestHeaderValue = requestHeaders[key] {
                if value != requestHeaderValue {
                    errorMessage += "\n  - Incorrect header value for \"\(key)\": expected \"\(value)\" got \"\(requestHeaderValue)\""
                }
                
            } else {
                errorMessage += "\n  - Missing header value for \"\(key)\""
            }
        }
        
        // Check query parameters
        let items = components.queryItems ?? []
        queryParameters?.forEach { (key, value) in
            if let requestValue = items[key] {
                if value != requestValue {
                    errorMessage += "\n  - Incorrect query value for \"\(key)\": expected \"\(value)\" got \"\(requestValue)\""
                }
                
            } else {
                errorMessage += "\n  - Missing query value for \"\(key)\""
            }
        }
        
        // Check the request body
        var requestBodyData: Data?
        
        if let data = httpBody {
            requestBodyData = data
        }
        
        if let stream = httpBodyStream {
            requestBodyData = Data(reading: stream)
        }
        
        guard let bodyData = requestBodyData else {
            if body != nil {
                errorMessage += "\n  - Missing request body"
            }
            return MatchResult.from(errorMessage)
        }
        
        guard let assertingBody = body,
            let assertingBodyData = try? JSONSerialization.data(withJSONObject: assertingBody) else {
                if body != nil {
                    errorMessage += "\n  - Asserting body is not a valid JSON object"
                }
            
                return MatchResult.from(errorMessage)
        }
        
        return CheckJSONEqual(assertingBodyData, bodyData)
            .map { MatchResult.failure("\(errorMessage)\n  - \($0)") }
            ?? MatchResult.from(errorMessage)
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
