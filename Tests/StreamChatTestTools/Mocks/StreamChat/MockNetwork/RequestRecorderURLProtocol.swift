//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

/// This URLProtocol subclass allows to intercept the network communication
/// and provides the latest network request made.
final class RequestRecorderURLProtocol: URLProtocol {
    static let testSessionHeaderKey = "RequestRecorderURLProtocol_test_session_id"
    
    /// Starts a new recording session. Adds a unique identifier to the configuration headers and listens only
    /// for the request with this id.
    static func startTestSession(with configuration: inout URLSessionConfiguration) {
        reset()
        let newSessionId = UUID().uuidString
        currentSessionId = newSessionId
        
        configuration.protocolClasses?.insert(RequestRecorderURLProtocol.self, at: 0)
        var existingHeaders = configuration.httpAdditionalHeaders ?? [:]
        existingHeaders[RequestRecorderURLProtocol.testSessionHeaderKey] = newSessionId
        configuration.httpAdditionalHeaders = existingHeaders
    }
    
    @Atomic private static var latestRequestExpectation: XCTestExpectation?
    @Atomic private static var latestRequest: URLRequest?
    
    /// Returns the latest network request this URLProtocol recorded.
    ///
    /// If no request has been made since the last time this function was invoked, it synchronously
    /// waits for the next request to be made.
    ///
    /// - Parameter timeout: Specifies the time the function waits for a new request to be made.
    static func waitForRequest(timeout: TimeInterval) -> URLRequest? {
        defer { reset() }
        guard latestRequest == nil else { return latestRequest }
        
        latestRequestExpectation = .init(description: "Wait for incoming request.")
        _ = XCTWaiter.wait(for: [latestRequestExpectation!], timeout: timeout)
        return latestRequest
    }
    
    /// If set, records only requests with `testSessionHeaderKey` header value set to this value. If `nil`,
    /// no requests are recorded.
    @Atomic static var currentSessionId: String?
    
    /// Cleans up existing waiters and recorded requests. We have to explictly reset the state because URLProtocols
    /// work with static variables.
    static func reset() {
        currentSessionId = nil
        latestRequest = nil
        latestRequestExpectation = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let sessionId = currentSessionId else { return false }
        
        if sessionId == request.value(forHTTPHeaderField: testSessionHeaderKey) {
            record(request: request)
        }
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Overriding this function is required by the superclass.
        request
    }
    
    private static func record(request: URLRequest) {
        guard latestRequest == nil else {
            log.info("Request for \(String(describing: currentSessionId)) already recoded. Skipping.")
            return
        }
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
