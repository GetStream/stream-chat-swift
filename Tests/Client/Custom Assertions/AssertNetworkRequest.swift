//
//  AssertNetworkRequest.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient


/// Synchronously waits for a network request to be made and asserts its properties.
///
/// The function always uses the latest request `RequestRecorderURLProtocol` records. If no request has
/// been made within the `timeout` period, this assertion fails with the time-out error.
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
///   - timeout: The maximum time this function waits for a request to be made.
///
func AssertNetworkRequest(method: Endpoint.Method,
                          path: String,
                          headers: [String: String]?,
                          queryParameters: [String: String]?,
                          body: [String: Any]?,
                          timeout: TimeInterval = 0.5,
                          file: StaticString = #file,
                          line: UInt = #line) {
    
    guard let request = RequestRecorderURLProtocol.waitForRequest(timeout: timeout) else {
        XCTFail("Waiting for request timed out. No request was made.", file: file, line: line)
        return
    }
    
    var errorMessage = ""
    defer {
        if !errorMessage.isEmpty {
            XCTFail("AssertNetworkRequest failed:" + errorMessage, file: file, line: line)
        }
    }
    
    // Check method
    if method.rawValue != request.httpMethod {
        errorMessage += "\n  - Incorrect method: expected \"\(method.rawValue)\" got \"\(request.httpMethod ?? "_")\""
    }
    
    guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        errorMessage += "\n  - Missing URL"
        return
    }
    
    // Check path
    if components.path != path {
        errorMessage += "\n  - Incorrect path: expected \"\(path)\" got \"\(components.path)\""
    }
    
    // Check headers
    let requestHeaders = request.allHTTPHeaderFields ?? [:]
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
    
    if let data = request.httpBody {
        requestBodyData = data
    }
    
    if let stream = request.httpBodyStream {
        requestBodyData = Data(reading: stream)
    }
    
    guard let bodyData = requestBodyData else {
        if body != nil {
            errorMessage += "\n  - Missing request body"
        }
        return
    }
    
    guard let assertingBody = body, let assertingBodyData = try? JSONSerialization.data(withJSONObject: assertingBody) else {
        if body != nil {
            errorMessage += "\n  - Asserting body is not a valid JSON object"
        }
        
        return
    }
    
    AssertJSONEqual(assertingBodyData, bodyData)
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
