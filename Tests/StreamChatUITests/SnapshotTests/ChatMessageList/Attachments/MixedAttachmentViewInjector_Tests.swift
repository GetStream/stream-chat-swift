//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

final class MixedAttachmentViewInjector_Tests: XCTestCase {
    func test_injectors_whenNoAttachments_isEmpty() {
        let message = ChatMessage.mock(attachments: [])
        let injectors = MixedAttachmentViewInjector.injectors(for: message)

        XCTAssertTrue(injectors.isEmpty)
    }

    func test_injectors_whenAttachments_containsInjectors() {
        let message = ChatMessage.mock(
            attachments: [.dummy(type: .image), .dummy(type: .file), .dummy(type: .voiceRecording)]
        )
        let injectors = MixedAttachmentViewInjector.injectors(for: message)

        AssertEqualInjectors(injectors, [
            GalleryAttachmentViewInjector.self,
            FilesAttachmentViewInjector.self,
            VoiceRecordingAttachmentViewInjector.self
        ])
    }

    func test_injectors_whenImageAndVideo_shouldNotHaveDuplicatedInjectors() {
        let message = ChatMessage.mock(
            attachments: [.dummy(type: .image), .dummy(type: .video), .dummy(type: .file)]
        )
        let injectors = MixedAttachmentViewInjector.injectors(for: message)

        AssertEqualInjectors(injectors, [
            GalleryAttachmentViewInjector.self,
            FilesAttachmentViewInjector.self
        ])
    }

    func test_injectors_whenCustomRegister_shouldIncludeCustomInjector() {
        MixedAttachmentViewInjector.register(.linkPreview, with: LinkAttachmentViewInjector.self)
        let message = ChatMessage.mock(
            attachments: [.dummy(type: .image), .dummy(type: .linkPreview)]
        )
        let injectors = MixedAttachmentViewInjector.injectors(for: message)

        AssertEqualInjectors(injectors, [
            GalleryAttachmentViewInjector.self,
            LinkAttachmentViewInjector.self
        ])
    }

    private func AssertEqualInjectors(
        _ lhs: [AttachmentViewInjector.Type],
        _ rhs: [AttachmentViewInjector.Type],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs.map(String.init(describing:)), rhs.map(String.init(describing:)))
    }
}
