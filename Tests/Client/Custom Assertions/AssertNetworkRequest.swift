//
//  AssertNetworkRequest.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient


extension AssertAsync {
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
                               line: UInt = #line) {
        AssertAsync {
            Assert.networkRequest(method: method,
                                  path: path,
                                  headers: headers,
                                  queryParameters: queryParameters,
                                  body: body,
                                  timeout: timeout,
                                  file: file,
                                  line: line)
        }
    }
}

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
        }, message: failureMessage(method, path, headers, queryParameters, body),
           file: file,
           line: line)
    }
    
    
    /// Failure message displayed in the network request assertion
    private static func failureMessage(_ method: Endpoint.Method,
                                       _ path: String,
                                       _ headers: [String: String]?,
                                       _ queryParameters: [String: String]?,
                                       _ body: [String: Any]?) -> String {
        
        let requests = RequestRecorderURLProtocol.recordedRequests
        
        let requestsDescription = requests
            .map { $0.description }
            .joined(separator: "\n")
        
        let requestsMatchingByPath = requests.filter { $0.matches(path: path) }
        
        let requestsMatchingByPathDescription = requestsMatchingByPath
            .map { request in
                request.description +
                "⛔️ Match failure: " +
                request.matches(method, path, headers, queryParameters, body).failureMessage
            }.joined(separator: "\n")

        return
            "Failed to find a matching request in the recorded request list (\(requests.count)):\n" +
            requestsDescription +
            "\nRecorded requests that at least match by path (\(requestsMatchingByPath.count)):\n" +
            requestsMatchingByPathDescription
    }
}

private extension URLRequest {
    enum MatchResult {
        case success
        case failure(String)
        
        /// Returns `success` if the message is empty. Otherwise it returns a failure with the given message.
        static func from(_ message: String) -> MatchResult {
            message.isEmpty ? .success : .failure(message)
        }
        
        /// Returns true if the value is `success`. Otherwise it returns false.
        var isSuccess: Bool {
            switch self {
            case .success:
                return true
            default:
                return false
            }
        }
        
        /// If the value is a failure it returns its message. Othewise it returns the empty string.
        var failureMessage: String {
            switch self {
            case .failure(let message):
                return message
            default:
                return ""
            }
        }
    }
    
    /// String description of a request: URL, HTTP method, headers and query items
    var description: String {
        guard let url = self.url else { return "" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        
        return "☏ URLRequest:\n" +
            "➔ url=\(url.absoluteString)\n" +
            "➔ method=\(httpMethod ?? "")\n" +
            "➔ headers=\(allHTTPHeaderFields ?? [:])\n" +
            "➔ queryItems=\(String(describing: queryItems))\n\n"
    }
    
    /// Returns `true` if the given parameters match the current `URLRequest`. Otherwise returns `false`.
    func matches(path: String) -> Bool {
        guard let url = self.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.path == path else {
                return false
        }
        return true
    }
    
    /// Returns `success` if the given path matches the current `URLRequest`.
    /// Otherwise returns `failure` with a String describing the reason it does not match.
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
        
        // Check if the body data JSON are equal if they are not then the error is appended
        // to the previous errors. If they are equal and there are no previous errors then
        // it returns `success` but if there are pending errors then it returns `failure`.
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
