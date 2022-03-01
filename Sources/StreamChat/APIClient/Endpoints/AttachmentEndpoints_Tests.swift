//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
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
                path: .uploadAttachment(channelId: id.cid.apiPath, type: pathComponent),
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
}
