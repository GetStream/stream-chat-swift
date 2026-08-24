//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

@MainActor final class FileAttachmentViewInjector_Tests: XCTestCase {
    private var contentView: ChatMessageContentView! = .init()
    private lazy var subject: FilesAttachmentViewInjector! = .init(contentView)

    override func tearDown() {
        subject = nil
        contentView = nil
        super.tearDown()
    }

    func test_fileAttachments_includesAudioAttachments() {
        let audio = ChatMessageAudioAttachment.mock(id: .unique)
        contentView.content = .mock(attachments: [audio.asAnyAttachment])

        let attachments = subject.fileAttachments

        XCTAssertEqual(attachments.map(\.payload.title), [audio.payload.title])
        XCTAssertEqual(attachments.first?.payload.assetURL, audio.payload.audioURL)
    }
}
