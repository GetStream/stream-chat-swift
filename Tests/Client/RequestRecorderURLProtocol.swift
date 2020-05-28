//
//  RequestRecorderURLProtocol.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

/// This URLProtocol subclass allows to intercept the network communication
/// and provides the latest network request made.
class RequestRecorderURLProtocol: URLProtocol {

    static let testSessionHeaderKey = "test_session_id"
    
    private static var latestRequestExpectation: XCTestExpectation?
    private static var latestRequest: URLRequest?

    /// Returns the latest network request this URLProtocol recorded.
    ///
    /// If no request has been made since the last time this function was invoked, it synchronously
    /// waits for the next request to be made.
    ///
    /// - Parameter timeout: Specifies the time the function waits for a new request to be made.
    static func waitForRequest(timeout: TimeInterval) -> URLRequest? {
        defer {
            // Delete the used request
            latestRequest = nil
        }

        guard latestRequest == nil else { return latestRequest }

        latestRequestExpectation = .init(description: "Wait for incoming request.")
        _ = XCTWaiter.wait(for: [latestRequestExpectation!], timeout: timeout)
        return latestRequest
    }

    /// If set, records only requests with `testSessionHeaderKey` header value set to this value. If `nil`, records all requests.
    static var currentSessionId: String?
    
    /// Cleans up existing waiters and recorded requests. We have to explictly reset the state because URLProtocols
    /// work with static variables.
    static func reset() {
        currentSessionId = nil
        latestRequest = nil
        latestRequestExpectation = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let sessionId = currentSessionId else {
            // No sessionId set, record all requests
            record(request: request)
            return false
        }
        
        if sessionId == request.value(forHTTPHeaderField: testSessionHeaderKey) {
            record(request: request)
        }
        return false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Overriding this function is required by the superclass.
        return request
    }

    private static func record(request: URLRequest) {
        latestRequest = request
        latestRequestExpectation?.fulfill()
    }
    
    // MARK: Instance methods

    override func startLoading() {
        // Required by the superclass.
    }

    override func stopLoading() {
        // Required by the superclass.
    }
}
