//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

/// This URLProtocol subclass allows to intercept the network communication
/// and provides the latest network request made.
final class RequestRecorderURLProtocol_Mock: URLProtocol {
    /// If set, records only requests with `testSessionHeaderKey` header value set to this value. If `nil`,
    /// no requests are recorded.
    static let currentSessionId = AllocatedUnfairLock<String?>(nil)
    private static let latestRequestExpectation = AllocatedUnfairLock<XCTestExpectation?>(nil)
    private static let latestRequest = AllocatedUnfairLock<URLRequest?>(nil)

    static let testSessionHeaderKey = "RequestRecorderURLProtocolMock_test_session_id"

    /// Starts a new recording session. Adds a unique identifier to the configuration headers and listens only
    /// for the request with this id.
    static func startTestSession(with configuration: inout URLSessionConfiguration) {
        reset()
        let newSessionId = UUID().uuidString
        currentSessionId.value = newSessionId

        configuration.protocolClasses?.insert(Self.self, at: 0)
        var existingHeaders = configuration.httpAdditionalHeaders ?? [:]
        existingHeaders[Self.testSessionHeaderKey] = newSessionId
        configuration.httpAdditionalHeaders = existingHeaders
    }

    /// Returns the latest network request this URLProtocol recorded.
    ///
    /// If no request has been made since the last time this function was invoked, it synchronously
    /// waits for the next request to be made.
    ///
    /// - Parameter timeout: Specifies the time the function waits for a new request to be made.
    static func waitForRequest(timeout: TimeInterval) -> URLRequest? {
        defer { reset() }
        guard latestRequest.value == nil else { return latestRequest.value }

        latestRequestExpectation.value = .init(description: "Wait for incoming request.")
        _ = XCTWaiter.wait(for: [latestRequestExpectation.value!], timeout: timeout)
        return latestRequest.value
    }

    /// Cleans up existing waiters and recorded requests. We have to explictly reset the state because URLProtocols
    /// work with static variables.
    static func reset() {
        currentSessionId.value = nil
        latestRequest.value = nil
        latestRequestExpectation.value = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let sessionId = currentSessionId.value else { return false }

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
        guard latestRequest.value == nil else {
            log.info("Request for \(String(describing: currentSessionId)) already recoded. Skipping.")
            return
        }
        latestRequest.value = request
        latestRequestExpectation.value?.fulfill()
    }

    // MARK: Instance methods

    override func startLoading() {
        // Required by the superclass.
    }

    override func stopLoading() {
        // Required by the superclass.
    }
}
