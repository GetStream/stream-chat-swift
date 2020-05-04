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

    override class func canInit(with request: URLRequest) -> Bool {
        DispatchQueue.main.async {
            latestRequest = request
            latestRequestExpectation?.fulfill()
        }
        return false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Overriding this function is required by the superclass.
        return request
    }

    // MARK: Instance methods

    override func startLoading() {
        // Required by the superclass.
    }

    override func stopLoading() {
        // Required by the superclass.
    }
}
