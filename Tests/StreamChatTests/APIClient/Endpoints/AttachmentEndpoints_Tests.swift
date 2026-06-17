//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AttachmentEndpoints_Tests: XCTestCase {
    func test_uploadAttachment_buildsCorrectly() {
        let id = AttachmentId(
            cid: .unique,
            messageId: .unique,
            index: .random(in: 0..<100)
        )

        let testCases: [AttachmentType: String] = [
            .image: "image",
            .video: "file",
            .audio: "file"
        ]

        for (type, pathComponent) in testCases {
            let expectedEndpoint: Endpoint<FileUploadPayload> = .init(
                path: .uploadChannelAttachment(channelId: id.cid.apiPath, type: pathComponent),
                method: .post,
                queryItems: nil,
                requiresConnectionId: false,
                body: nil
            )

            // Build endpoint
            let endpoint: Endpoint<FileUploadPayload> = .uploadAttachment(with: id.cid, type: type)

            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual("channels/\(id.cid.type.rawValue)/\(id.cid.id)/\(pathComponent)", endpoint.path.value)
        }
    }
    
    func test_deleteAttachment_buildsCorrectly() {
        let remoteURL = URL.unique()
        
        let testCases: [AttachmentType: String] = [
            .image: "image",
            .video: "file",
            .audio: "file",
            .file: "file"
        ]
        
        for (type, pathComponent) in testCases {
            let expectedEndpoint: Endpoint<EmptyResponse> = .init(
                path: .uploadAttachment(pathComponent),
                method: .delete,
                queryItems: nil,
                requiresConnectionId: false,
                body: ["url": remoteURL.absoluteString]
            )
            
            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .deleteAttachment(url: remoteURL, type: type)
            
            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual(endpoint.method, .delete, "Method should be DELETE for \(type)")
            XCTAssertEqual(endpoint.path.value, "uploads/\(pathComponent)", "Path should be \(pathComponent) for \(type)")
            XCTAssertFalse(endpoint.requiresConnectionId, "Should not require connection ID")
            
            // Verify body contains the URL
            let body = endpoint.body as? [String: String]
            XCTAssertEqual(body?["url"], remoteURL.absoluteString, "Body should contain the remote URL for \(type)")
        }
    }
    
    func test_deleteAttachment_imageType_usesImagePath() {
        let remoteURL = URL.unique()
        let endpoint: Endpoint<EmptyResponse> = .deleteAttachment(url: remoteURL, type: .image)
        
        XCTAssertEqual(endpoint.path.value, "uploads/image")
        XCTAssertEqual(endpoint.method, .delete)
    }
    
    func test_deleteAttachment_nonImageType_usesFilePath() {
        let remoteURL = URL.unique()
        let nonImageTypes: [AttachmentType] = [.video, .audio, .file]
        
        for type in nonImageTypes {
            let endpoint: Endpoint<EmptyResponse> = .deleteAttachment(url: remoteURL, type: type)
            
            XCTAssertEqual(endpoint.path.value, "uploads/file", "Path should be 'file' for \(type)")
            XCTAssertEqual(endpoint.method, .delete)
        }
    }
}
