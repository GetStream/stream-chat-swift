//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

/// Mock implementation of APIClient allowing easy control and simulation of responses.
final class APIClient_Spy: APIClient, Spy {
    enum Signature {
        static let flushRequestsQueue = "flushRequestsQueue()"
    }
    var recordedFunctions: [String] = []

    /// The last endpoint `request` function was called with.
    @Atomic var request_endpoint: AnyEndpoint?
    @Atomic var request_completion: Any?
    @Atomic private var request_result: Any?
    @Atomic var request_allRecordedCalls: [(endpoint: AnyEndpoint, completion: Any?)] = []

    /// The last endpoint `recoveryRequest` function was called with.
    @Atomic var recoveryRequest_endpoint: AnyEndpoint?
    @Atomic var recoveryRequest_completion: Any?
    @Atomic var recoveryRequest_allRecordedCalls: [(endpoint: AnyEndpoint, completion: Any?)] = []

    /// The last endpoint `unmanagedRequest` function was called with.
    @Atomic private var unmanagedRequest_result: Any?
    @Atomic var unmanagedRequest_endpoint: AnyEndpoint?
    @Atomic var unmanagedRequest_completion: Any?
    @Atomic var unmanagedRequest_allRecordedCalls: [(endpoint: AnyEndpoint, completion: Any?)] = []

    /// The last endpoint `uploadFile` function was called with.
    @Atomic var uploadFile_attachment: AnyChatMessageAttachment?
    @Atomic var uploadFile_progress: ((Double) -> Void)?
    @Atomic var uploadFile_completion: ((Result<UploadedAttachment, Error>) -> Void)?
    @Atomic var uploadFile_callCount = 0

    @Atomic var init_sessionConfiguration: URLSessionConfiguration
    @Atomic var init_requestEncoder: RequestEncoder
    @Atomic var init_requestDecoder: RequestDecoder
    @Atomic var init_attachmentUploader: AttachmentUploader
    @Atomic var request_expectation: XCTestExpectation
    @Atomic var recoveryRequest_expectation: XCTestExpectation
    @Atomic var uploadRequest_expectation: XCTestExpectation

    // Cleans up all recorded values
    func cleanUp() {
        request_allRecordedCalls = []
        request_endpoint = nil
        request_completion = nil
        request_expectation = .init()
        recoveryRequest_expectation = .init()
        uploadRequest_expectation = .init()

        recoveryRequest_endpoint = nil
        recoveryRequest_allRecordedCalls = []
        recoveryRequest_completion = nil

        uploadFile_attachment = nil
        uploadFile_progress = nil
        uploadFile_completion = nil

        flushRequestsQueue()
    }

    override init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        requestDecoder: RequestDecoder,
        attachmentUploader: AttachmentUploader
    ) {
        init_sessionConfiguration = sessionConfiguration
        init_requestEncoder = requestEncoder
        init_requestDecoder = requestDecoder
        init_attachmentUploader = attachmentUploader
        request_expectation = .init()
        recoveryRequest_expectation = .init()
        uploadRequest_expectation = .init()

        super.init(
            sessionConfiguration: sessionConfiguration,
            requestEncoder: requestEncoder,
            requestDecoder: requestDecoder,
            attachmentUploader: attachmentUploader
        )
    }

    /// Simulates the response of the last `request` method call
    func test_simulateResponse<Response: Decodable>(_ response: Result<Response, Error>) {
        let completion = request_completion as? ((Result<Response, Error>) -> Void)
        completion?(response)
    }

    func test_simulateRecoveryResponse<Response: Decodable>(_ response: Result<Response, Error>) {
        let completion = recoveryRequest_completion as? ((Result<Response, Error>) -> Void)
        completion?(response)
    }

    func test_mockResponseResult<Response: Decodable>(_ responseResult: Result<Response, Error>) {
        request_result = responseResult
    }

    func test_mockUnmanagedResponseResult<Response: Decodable>(_ responseResult: Result<Response, Error>) {
        unmanagedRequest_result = responseResult
    }

    override func request<Response>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response: Decodable {
        request_endpoint = AnyEndpoint(endpoint)
        if let result = request_result as? Result<Response, Error> {
            completion(result)
        }
        request_completion = completion
        _request_allRecordedCalls.mutate { $0.append((request_endpoint!, request_completion!)) }
        request_expectation.fulfill()
    }

    override func recoveryRequest<Response>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response: Decodable {
        recoveryRequest_endpoint = AnyEndpoint(endpoint)
        recoveryRequest_completion = completion
        _recoveryRequest_allRecordedCalls.mutate { $0.append((recoveryRequest_endpoint!, recoveryRequest_completion!)) }
    }

    override func unmanagedRequest<Response>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response : Decodable {
        unmanagedRequest_endpoint = AnyEndpoint(endpoint)
        unmanagedRequest_completion = completion
        _unmanagedRequest_allRecordedCalls.mutate { $0.append((unmanagedRequest_endpoint!, unmanagedRequest_completion!)) }
        if let result = unmanagedRequest_result as? Result<Response, Error> {
            completion(result)
        }
    }

    override func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    ) {

        uploadFile_attachment = attachment
        uploadFile_progress = progress
        uploadFile_completion = completion
        uploadFile_callCount += 1
        uploadRequest_expectation.fulfill()
    }

    override func flushRequestsQueue() {
        record()
    }

    @discardableResult
    func waitForRequest(timeout: Double = defaultTimeout) -> AnyEndpoint? {
        XCTWaiter().wait(for: [request_expectation], timeout: timeout)
        return request_endpoint
    }

    @discardableResult
    func waitForRecoveryRequest(timeout: Double = defaultTimeout) -> AnyEndpoint? {
        XCTWaiter().wait(for: [recoveryRequest_expectation], timeout: timeout)
        return recoveryRequest_endpoint
    }

    override func enterRecoveryMode() {
        record()
        super.enterRecoveryMode()
    }

    override func exitRecoveryMode() {
        record()
        super.exitRecoveryMode()
    }
}

extension APIClient_Spy {
    convenience init() {
        self.init(
            sessionConfiguration: .ephemeral,
            requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
            requestDecoder: DefaultRequestDecoder(),
            attachmentUploader: AttachmentUploader_Spy()
        )
    }
}
