//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

public extension StreamMockServer {
    func configureAttachmentEndpoints() {
        server.register(MockEndpoint.image) { [weak self] _ in
            self?.attachmentCreation(fileUrl: Attachments.image)
        }
        server.register(MockEndpoint.file) { [weak self] _ in
            self?.attachmentCreation(fileUrl: Attachments.file)
        }
    }

    private func attachmentCreation(fileUrl: String) -> HttpResponse {
        var json = TestData.toJson(.httpAttachment)
        json[JSONKey.file] = fileUrl
        return .ok(.json(json))
    }
}
