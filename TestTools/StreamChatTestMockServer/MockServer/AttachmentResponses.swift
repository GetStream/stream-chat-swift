//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

public extension StreamMockServer {
    
    func configureAttachmentEndpoints() {
        server.register(MockEndpoint.image) { [weak self] request in
            self?.attachmentCreation(fileUrl: Attachments.image)
        }
        server.register(MockEndpoint.file) { [weak self] request in
            self?.attachmentCreation(fileUrl: Attachments.file)
        }
    }
    
    private func attachmentCreation(fileUrl: String) -> HttpResponse {
        var json = TestData.toJson(.httpAttachment)
        json[JSONKey.file] = fileUrl
        return .ok(.json(json))
    }
    
}
