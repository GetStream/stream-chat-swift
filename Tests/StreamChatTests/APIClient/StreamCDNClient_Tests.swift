//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StreamCDNClient_Tests: XCTestCase {
    func test_uploadFileEncoderIsCalledWithEndpoint() throws {
        let builder = TestBuilder()
        let client = builder.make()

        // Setup mock encoder response (it's not actually used, we just need to return something)
        let request = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(request)

        // Create a test endpoint
        let attachmentId = AttachmentId.unique
        let testEndpoint: Endpoint<FileUploadPayload> = .uploadAttachment(
            with: attachmentId.cid,
            type: .image
        )

        // Simulate file uploading
        client.uploadAttachment(
            .dummy(
                id: attachmentId,
                uploadingState: .init(
                    localFileURL: .localYodaImage,
                    state: .pendingUpload,
                    file: .init(type: .jpeg, size: 0, mimeType: nil)
                )
            ),
            progress: nil,
            completion: { (_: Result<UploadedFile, Error>) in }
        )

        // Check the encoder is called with the correct endpoint
        XCTAssertEqual(builder.encoder.encodeRequest_endpoints.first, AnyEndpoint(testEndpoint))
    }
    
    func test_standaloneUploadFileEncoderIsCalledWithEndpoint() throws {
        let builder = TestBuilder()
        let client = builder.make()

        // Setup mock encoder response (it's not actually used, we just need to return something)
        let request = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(request)
        
        let payload = try Data(contentsOf: .localYodaImage)

        // Create a test endpoint
        let testEndpoint: Endpoint<FileUploadPayload> = .uploadAttachment(type: .image)
        
        let uploadingState = AttachmentUploadingState(
            localFileURL: .localYodaImage,
            state: .pendingUpload,
            file: .init(type: .png, size: 120, mimeType: "image/png")
        )

        // Simulate file uploading
        client.uploadStandaloneAttachment(
            .mock(
                payload: payload,
                uploadingState: uploadingState
            ),
            progress: nil,
            completion: { (_: Result<UploadedFile, Error>) in }
        )

        // Check the encoder is called with the correct endpoint
        XCTAssertEqual(builder.encoder.encodeRequest_endpoints.first, AnyEndpoint(testEndpoint))
    }

    func test_uploadFileEncoderFailingToEncode() throws {
        let builder = TestBuilder()
        let client = builder.make()
        // Setup mock encoder response to fail with `testError`
        let testError = TestError()
        builder.encoder.encodeRequest = .failure(testError)

        let payload = try Data(contentsOf: .localYodaImage)
        
        let uploadingState = AttachmentUploadingState(
            localFileURL: .localYodaImage,
            state: .pendingUpload,
            file: .init(type: .png, size: 120, mimeType: "image/png")
        )
        
        // Create a request and assert the result is failure
        let result: Result<UploadedFile, Error> = try waitFor {
            client.uploadStandaloneAttachment(
                .mock(
                    payload: payload,
                    uploadingState: uploadingState
                ),
                progress: nil,
                completion: $0
            )
        }

        XCTAssertEqual(result.error as? TestError, testError)
    }
    
    func test_uploadStandaloneFileEncoderFailingToEncode() throws {
        let builder = TestBuilder()
        let client = builder.make()
        // Setup mock encoder response to fail with `testError`
        let testError = TestError()
        builder.encoder.encodeRequest = .failure(testError)

        // Create a request and assert the result is failure
        let result: Result<UploadedFile, Error> = try waitFor {
            client.uploadAttachment(
                .dummy(
                    uploadingState: .init(
                        localFileURL: .localYodaImage,
                        state: .pendingUpload,
                        file: .init(type: .jpeg, size: 0, mimeType: nil)
                    )
                ),
                progress: nil,
                completion: $0
            )
        }

        XCTAssertEqual(result.error as? TestError, testError)
    }

    func test_uploadFileSuccess() throws {
        let builder = TestBuilder()
        let decoder = builder.decoder
        let client = builder.make()

        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(testRequest)

        // Set up a successful mock network response for the request
        let mockResponseData = try JSONEncoder.stream.encode(["file": URL.unique()])
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 234, responseBody: mockResponseData)

        // Set up a decoder response
        // ⚠️ Watch out: the user is different there, so we can distinguish between the incoming data
        // to the encoder, and the outgoing data).
        let payload = FileUploadPayload(fileURL: .unique(), thumbURL: .unique())
        decoder.decodeRequestResponse = .success(payload)

        // Create a request and wait for the completion block
        let result: Result<UploadedFile, Error> = try waitFor {
            client.uploadAttachment(
                .dummy(
                    uploadingState: .init(
                        localFileURL: .localYodaImage,
                        state: .pendingUpload,
                        file: .init(type: .jpeg, size: 0, mimeType: nil)
                    )
                ),
                progress: nil,
                completion: $0
            )
        }

        // Check the incoming data to the encoder is the URLResponse and data from the network
        XCTAssertEqual(decoder.decodeRequestResponse_data, mockResponseData)
        XCTAssertEqual(decoder.decodeRequestResponse_response?.statusCode, 234)

        // Check the outgoing data is from the decoder
        XCTAssertEqual(try result.get().fileURL, payload.fileURL)
    }
    
    func test_standaloneUploadFileSuccess() throws {
        let builder = TestBuilder()
        let decoder = builder.decoder
        let client = builder.make()

        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(testRequest)

        // Set up a successful mock network response for the request
        let url = URL.unique()
        let mockResponseData = try JSONEncoder.stream.encode(["file": url])
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 234, responseBody: mockResponseData)
        
        let response = FileUploadPayload(fileURL: .unique(), thumbURL: .unique())
        decoder.decodeRequestResponse = .success(response)

        let payload = try Data(contentsOf: .localYodaImage)
        
        let uploadingState = AttachmentUploadingState(
            localFileURL: .localYodaImage,
            state: .pendingUpload,
            file: .init(type: .png, size: 120, mimeType: "image/png")
        )
        
        // Create a request and assert the result is failure
        let result: Result<UploadedFile, Error> = try waitFor {
            client.uploadStandaloneAttachment(
                .mock(
                    payload: payload,
                    uploadingState: uploadingState
                ),
                progress: nil,
                completion: $0
            )
        }

        // Check the incoming data to the encoder is the URLResponse and data from the network
        XCTAssertEqual(decoder.decodeRequestResponse_data, mockResponseData)
        XCTAssertEqual(decoder.decodeRequestResponse_response?.statusCode, 234)

        XCTAssertEqual(try result.get().fileURL, response.fileURL)
    }

    func test_uploadFileFailure() throws {
        let builder = TestBuilder()
        let client = builder.make()
        let decoder = builder.decoder

        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(testRequest)

        // We cannot use `TestError` since iOS14 wraps this into another error
        let networkError = NSError(domain: "TestNetworkError", code: -1, userInfo: nil)
        let encoderError = TestError()

        // Set up a mock network response from the request
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 444, error: networkError)

        // Set up a decoder response to return `encoderError`
        decoder.decodeRequestResponse = .failure(encoderError)

        // Create a request and wait for the completion block
        let result: Result<UploadedFile, Error> = try waitFor {
            client.uploadAttachment(
                .dummy(
                    uploadingState: .init(
                        localFileURL: .localYodaImage,
                        state: .pendingUpload,
                        file: .init(type: .jpeg, size: 0, mimeType: nil)
                    )
                ),
                progress: nil,
                completion: $0
            )
        }

        // Check the incoming error to the encoder is the error from the response
        XCTAssertNotNil(decoder.decodeRequestResponse_error)

        // We have to compare error codes, since iOS14 wraps network errors into `NSURLError`
        // in which we cannot retrieve the wrapper error
        XCTAssertEqual((decoder.decodeRequestResponse_error as NSError?)?.code, networkError.code)

        // Check the outgoing data is from the decoder
        XCTAssertEqual(result.error as? TestError, encoderError)
    }
    
    func test_standaloneUploadFileFailure() throws {
        let builder = TestBuilder()
        let client = builder.make()
        let decoder = builder.decoder

        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(testRequest)

        // We cannot use `TestError` since iOS14 wraps this into another error
        let networkError = NSError(domain: "TestNetworkError", code: -1, userInfo: nil)
        let encoderError = TestError()

        // Set up a mock network response from the request
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 444, error: networkError)

        // Set up a decoder response to return `encoderError`
        decoder.decodeRequestResponse = .failure(encoderError)
        
        let payload = try Data(contentsOf: .localYodaImage)
        
        let uploadingState = AttachmentUploadingState(
            localFileURL: .localYodaImage,
            state: .pendingUpload,
            file: .init(type: .png, size: 120, mimeType: "image/png")
        )

        // Create a request and wait for the completion block
        let result: Result<UploadedFile, Error> = try waitFor {
            client.uploadStandaloneAttachment(
                .mock(
                    payload: payload,
                    uploadingState: uploadingState
                ),
                progress: nil,
                completion: $0
            )
        }

        // Check the incoming error to the encoder is the error from the response
        XCTAssertNotNil(decoder.decodeRequestResponse_error)

        // We have to compare error codes, since iOS14 wraps network errors into `NSURLError`
        // in which we cannot retrieve the wrapper error
        XCTAssertEqual((decoder.decodeRequestResponse_error as NSError?)?.code, networkError.code)

        // Check the outgoing data is from the decoder
        XCTAssertEqual(result.error as? TestError, encoderError)
    }

    func test_callingUploadFile_createsNetworkRequest() throws {
        let builder = TestBuilder()
        let client = builder.make()

        let attachment = AnyChatMessageAttachment.dummy(
            uploadingState: .init(
                localFileURL: .localYodaImage,
                state: .pendingUpload,
                file: .init(type: .jpeg, size: 0, mimeType: nil)
            )
        )

        let uploadingState = try XCTUnwrap(attachment.uploadingState)

        let multipartFormData = MultipartFormData(
            try Data(contentsOf: .localYodaImage),
            fileName: uploadingState.localFileURL.lastPathComponent,
            mimeType: uploadingState.file.type.mimeType
        )

        let uniquePath: String = .unique
        let uniqueQueryItem: String = .unique
        var testRequest = URLRequest(url: URL(string: "test://test.test/\(uniquePath)?item=\(uniqueQueryItem)")!)
        testRequest.httpMethod = "post"
        builder.encoder.encodeRequest = .success(testRequest)

        // Simulate file uploading.
        client.uploadAttachment(
            .dummy(
                uploadingState: .init(
                    localFileURL: .localYodaImage,
                    state: .pendingUpload,
                    file: .init(type: .jpeg, size: 0, mimeType: nil)
                )
            ),
            progress: nil,
            completion: { (_: Result<UploadedFile, Error>) in }
        )

        // Check a network request is made with the values from `testRequest`
        AssertNetworkRequest(
            method: .post,
            path: "/" + uniquePath,
            headers: [
                "Content-Type": "multipart/form-data; boundary=\(MultipartFormData.boundary)"
            ],
            queryParameters: ["item": uniqueQueryItem],
            body: multipartFormData.getMultipartFormData()
        )
    }
    
    // MARK: - Delete Attachment Tests
    
    func test_deleteAttachmentEncoderIsCalledWithEndpoint() throws {
        let builder = TestBuilder()
        let client = builder.make()

        // Setup mock encoder response (it's not actually used, we just need to return something)
        let request = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(request)

        // Create test values
        let remoteURL = URL.unique()
        let testEndpoint: Endpoint<EmptyResponse> = .deleteAttachment(url: remoteURL, type: .image)

        // Simulate file deletion
        client.deleteAttachment(
            remoteUrl: remoteURL,
            completion: { _ in }
        )

        // Check the encoder is called with the correct endpoint
        XCTAssertEqual(builder.encoder.encodeRequest_endpoints.first, AnyEndpoint(testEndpoint))
    }
    
    func test_deleteAttachmentEncoderFailingToEncode() throws {
        let builder = TestBuilder()
        let client = builder.make()
        
        // Setup mock encoder response to fail with `testError`
        let testError = TestError()
        builder.encoder.encodeRequest = .failure(testError)

        let remoteURL = URL.unique()

        // Create a request and assert the result is failure
        let result: Error? = try waitFor {
            client.deleteAttachment(
                remoteUrl: remoteURL,
                completion: $0
            )
        }

        XCTAssertEqual(result as? TestError, testError)
    }
    
    func test_deleteAttachmentSuccess() throws {
        let builder = TestBuilder()
        let client = builder.make()

        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(testRequest)

        // Set up a successful mock network response for the request (no body needed for delete)
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 200)

        let remoteURL = URL.unique()

        // Create a request and wait for the completion block
        let result: Error? = try waitFor {
            client.deleteAttachment(
                remoteUrl: remoteURL,
                completion: $0
            )
        }

        // Check the result is successful (nil error)
        XCTAssertNil(result)
    }
    
    func test_deleteAttachmentFailure() throws {
        let builder = TestBuilder()
        let client = builder.make()

        // Create a test request and set it as a response from the encoder
        let testRequest = URLRequest(url: .unique())
        builder.encoder.encodeRequest = .success(testRequest)

        // We cannot use `TestError` since iOS14 wraps this into another error
        let networkError = NSError(domain: "TestNetworkError", code: -1, userInfo: nil)

        // Set up a mock network response from the request with error
        URLProtocol_Mock.mockResponse(request: testRequest, statusCode: 404, error: networkError)

        let remoteURL = URL.unique()

        // Create a request and wait for the completion block
        let result: Error? = try waitFor {
            client.deleteAttachment(
                remoteUrl: remoteURL,
                completion: $0
            )
        }

        // Check the error is propagated
        XCTAssertNotNil(result)
    }
}
