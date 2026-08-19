//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

@MainActor final class AttachmentViewCatalog_Tests: XCTestCase {
    func test_audioOnly_usesFilesInjector() {
        let message = ChatMessage.mock(attachments: [.dummy(type: .audio)])

        let injector = AttachmentViewCatalog.attachmentViewInjectorClassFor(
            message: message,
            components: .default
        )

        XCTAssertTrue(injector == FilesAttachmentViewInjector.self)
    }

    func test_fileAndAudio_usesFilesInjector() {
        let message = ChatMessage.mock(attachments: [.dummy(type: .file), .dummy(type: .audio)])

        let injector = AttachmentViewCatalog.attachmentViewInjectorClassFor(
            message: message,
            components: .default
        )

        XCTAssertTrue(injector == FilesAttachmentViewInjector.self)
    }

    func test_imageAndAudio_usesMixedInjector() {
        let message = ChatMessage.mock(attachments: [.dummy(type: .image), .dummy(type: .audio)])

        let injector = AttachmentViewCatalog.attachmentViewInjectorClassFor(
            message: message,
            components: .default
        )

        XCTAssertTrue(injector == MixedAttachmentViewInjector.self)
    }
}
